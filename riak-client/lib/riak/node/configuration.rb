require 'pathname'
require 'yaml'

module Riak
  class Node
    # The directories (and accessor methods) that will be created
    # under the generated node.
    NODE_DIRECTORIES = [:bin, :etc, :log, :data, :ring, :pipe]

    NODE_DIRECTORIES.each do |dir|
      # Makes accessor methods for all the node directories that
      # return Pathname objects.
      class_eval %Q{
        def #{dir}
          root + '#{dir}'
        end
      }
    end

    # @return [Hash] the contents of the Erlang environment, which will
    #   be created into the app.config file.
    attr_reader :env

    # @return [Hash] the command-line switches for the Erlang virtual
    #   machine, which will be created into the vm.args file
    attr_reader :vm

    # @return [Hash] the configuration that was passed to the Node
    #   when initialized
    attr_reader :configuration

    # @return [Array<Pathname>] where user Erlang code will be loaded from
    def erlang_sources
      env[:riak_kv][:add_paths].map {|p| Pathname.new(p) }
    end

    # @return [Pathname] where user Javascript code will be loaded from
    def javascript_source
      Pathname.new(env[:riak_kv][:js_source_dir])
    end

    # @return [Fixnum] the size of the ring, i.e. number of partitions
    def ring_size
      env[:riak_core][:ring_creation_size]
    end

    # @return [Fixnum] The port used for handing off data to other nodes.
    def handoff_port
      env[:riak_core][:handoff_port]
    end

    # @return [Fixnum] The port to which the HTTP API is connected.
    def http_port
      # We'll only support 0.14 and later, which uses http rather than web_ip/web_port
      env[:riak_core][:http][0][1]
    end

    # @return [Fixnum] the port to which the Protocol Buffers API is connected.
    def pb_port
      env[:riak_kv][:pb_port]
    end

    # @return [String] the interface to which the HTTP API is connected
    def http_ip
      env[:riak_core][:http][0][0]
    end

    # @return [String] the interface to which the Protocol Buffers API is connected
    def pb_ip
      env[:riak_kv][:pb_ip]
    end

    # @return [Symbol] the storage backend for Riak Search.
    def search_backend
      env[:riak_search][:search_backend]
    end

    # @return [Symbol] the storage backend for Riak KV.
    def kv_backend
      env[:riak_kv][:storage_backend]
    end

    # @return [String] the name of the Riak node as seen by distributed Erlang
    #   communication. AKA "-name" in vm.args.
    def name
      vm['-name']
    end

    # @return [String] the cookie/shared secret used for connecting
    #    a cluster
    def cookie
      vm['-setcookie']
    end

    # The source of the Riak installation from where the {Node} will
    # be generated. This should point to the directory that contains
    # the 'riak[search]' and 'riak[search]-admin' scripts.
    # @return [Pathname] the source Riak installation
    attr_reader :source

    # The root directory of the {Node}, where all files are placed
    # after generation.
    # @return [Pathname] the root directory of the node
    attr_reader :root

    # The script for starting, stopping and pinging the Node.
    # @return [Pathname] the path to the control script
    def control_script
      @control_script ||= root + 'bin' + control_script_name
    end

    # The name of the 'riak' or 'riaksearch' control script.
    # @return [String] 'riak' or 'riaksearch'
    def control_script_name
      @control_script_name ||= (source + 'riaksearch').exist? ? 'riaksearch' : 'riak'
    end

    # The script for controlling non-lifecycle features of Riak like
    # joining, leaving, status, ringready, etc.
    # @return [Pathname] the path to the administrative script
    def admin_script
      @admin_script ||= root + 'bin' + "#{control_script_name}-admin"
    end

    # The "manifest" file where the node configuration will be
    # written.
    # @return [Pathname] the path to the manifest
    def manifest
      root + '.node.yml'
    end

    protected
    # Populates the proper node configuration from the input config.
    def configure(hash)
      raise ArgumentError, t('source_and_root_required') unless hash[:source] && hash[:root]
      @configuration = hash
      configure_paths
      configure_manifest
      configure_settings
      configure_logging
      configure_data
      configure_ports(hash[:interface], hash[:min_port])
      configure_name(hash[:interface])
    end

    # Reads the manifest if it exists, overrides the passed configuration.
    def configure_manifest
      @configuration = YAML.load_file(manifest.to_s) if exist?
    end

    # Sets the data directories for the various on-disk backends and
    # the ring state.
    def configure_data
      [:bitcask, :eleveldb, :merge_index].each {|k| env[k] ||= {} }
      env[:bitcask][:data_root] ||= (data + 'bitcask').expand_path.to_s
      env[:eleveldb][:data_root] ||= (data + 'leveldb').expand_path.to_s
      env[:merge_index][:data_root] ||= (data + 'merge_index').expand_path.to_s
      env[:riak_core][:ring_state_dir] ||= ring.expand_path.to_s
      NODE_DIRECTORIES.each do |dir|
        next if [:ring, :pipe].include?(dir)
        env[:riak_core][:"platform_#{dir}_dir"] ||= send(dir).to_s
      end
    end

    # Sets directories and handlers for logging.
    def configure_logging
      if env[:lager]
        env[:lager][:handlers] = {
          :lager_file_backend => [
                                  Tuple[(log+"error.log").expand_path.to_s, :error],
                                  Tuple[(log+"console.log").expand_path.to_s, :info]
                                 ]
        }
        env[:lager][:crash_log] = (log+"crash.log").to_s
      else
        # TODO: Need a better way to detect this, the defaults point
        # to 1.0-style configs. Maybe there should be some kind of
        # detection routine.
        # Use sasl error logger for 0.14.
        env[:riak_err] ||= {
          :term_max_size => 65536,
          :fmt_max_bytes => 65536
        }
        env[:sasl] = {
          :sasl_error_logger => Tuple[:file, (log+"sasl-error.log").expand_path.to_s],
          :errlog_type => :error,
          :error_logger_mf_dir => (log+"sasl").expand_path.to_s,
          :error_logger_mf_maxbytes => 10485760,
          :error_logger_mf_maxfiles => 5
        }
      end
      vm['-env ERL_CRASH_DUMP'] =  (log + 'erl_crash.dump').to_s
    end

    # Sets the node name and cookie for distributed Erlang.
    def configure_name(interface)
      interface ||= "127.0.0.1"
      vm["-name"] ||= configuration[:name] || "riak#{rand(1000000).to_s}@#{interface}"
      vm["-setcookie"] ||= configuration[:cookie] || "#{rand(100000).to_s}_#{rand(1000000).to_s}"
    end

    # Merges input configuration with the defaults.
    def configure_settings
      @env = deep_merge(env.dup, configuration[:env]) if configuration[:env]
      @vm = vm.merge(configuration[:vm]) if configuration[:vm]
    end

    # Sets the source directory and root directory of the generated node.
    def configure_paths
      @source = Pathname.new(configuration[:source]).expand_path
      @root = Pathname.new(configuration[:root]).expand_path
    end

    # Sets ports and interfaces for http, protocol buffers, and handoff.
    def configure_ports(interface, min_port)
      interface ||= "127.0.0.1"
      min_port ||= 8080
      unless env[:riak_core][:http]
        env[:riak_core][:http] = [Tuple[interface, min_port]]
        min_port += 1
      end
      env[:riak_core][:http] = env[:riak_core][:http].map {|pair| Tuple[*pair] }
      env[:riak_kv][:pb_ip] = interface unless env[:riak_kv][:pb_ip]
      unless env[:riak_kv][:pb_port]
        env[:riak_kv][:pb_port] = min_port
        min_port += 1
      end
      unless env[:riak_core][:handoff_port]
        env[:riak_core][:handoff_port] = min_port
        min_port += 1
      end
    end

    # Implements a deep-merge of two {Hash} instances.
    # @param [Hash] source the original hash
    # @param [Hash] target the new hash
    # @return [Hash] a {Hash} whose {Hash} values have also been merged
    def deep_merge(source, target)
      source.merge(target) do |key, old_val, new_val|
        if Hash === old_val && Hash === new_val
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end

    # This class lets us specify that some settings should be emitted
    # as Erlang tuples, even though the first element is not
    # necessarily a Symbol.
    class Tuple < Array; end

    # Recursively converts a {Hash} into an Erlang configuration
    # string that is appropriate for the app.config file.
    # @param [Hash] hash a collection of configuration values
    # @param [Fixnum] depth the current nesting level of
    #    generation/indentation
    # @return [String] Erlang proplists in a String for use in
    #   app.config
    def to_erlang_config(hash, depth = 1)
      padding = '    ' * depth
      parent_padding = '    ' * (depth-1)
      values = hash.map do |k,v|
        "{#{k}, #{value_to_erlang(v, depth)}}"
      end.join(",\n#{padding}")
      "[\n#{padding}#{values}\n#{parent_padding}]"
    end

    # Converts a value to an Erlang term. Mutually recursive with
    # {#to_erlang_config}.
    def value_to_erlang(v, depth=1)
      case v
      when Hash
        to_erlang_config(v, depth+1)
      when String
        "\"#{v}\""
      when Tuple
        "{" << v.map {|i| value_to_erlang(i, depth+1) }.join(", ") << "}"
      when Array
        "[" << v.map {|i| value_to_erlang(i, depth+1) }.join(", ") << "]"
      else
        v.to_s
      end
    end
  end
end
