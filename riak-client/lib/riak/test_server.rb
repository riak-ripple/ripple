# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'riak'
require 'tempfile'

module Riak
  class TestServer
    APP_CONFIG_DEFAULTS = {
      :riak_core => {
        :web_ip => "127.0.0.1",
        :web_port => 9000,
        :handoff_port => 9001,
        :ring_creation_size => 64
      },
      :riak_kv => {
        :storage_backend => :riak_kv_ets_backend,
        :pb_ip => "127.0.0.1",
        :pb_port => 9002,
        :js_vm_count => 8,
        :js_max_vm_mem => 8,
        :js_thread_stack => 16,
        :riak_kv_stat => true
      }
    }
    VM_ARGS_DEFAULTS = {
      "-name" => "riaktest#{rand(1000000).to_s}@127.0.0.1",
      "-setcookie" => "#{rand(1000000).to_s}_#{rand(1000000).to_s}",
      "+K" => true,
      "+A" => 64,
      "-smp" => "enable",
      "-env ERL_MAX_PORTS" => 4096,
      "-env ERL_FULLSWEEP_AFTER" => 10
    }
    DEFAULTS = {
      :app_config => APP_CONFIG_DEFAULTS,
      :vm_args => VM_ARGS_DEFAULTS,
      :temp_dir => File.join(Dir.tmpdir,'riaktest'),
      :user => ::ENV['USER']
    }
    attr_accessor :temp_dir

    def initialize(options={})
      options   = deep_merge(DEFAULTS.dup, options)
      @temp_dir = File.expand_path(options[:temp_dir])
      @user     = options[:user]
      @bin_dir  = File.expand_path(options[:bin_dir])
      options[:app_config][:riak_core][:ring_state_dir] ||= File.join(@temp_dir, "data", "ring")
      @app_config = options[:app_config]
      @vm_args    = options[:vm_args]
    end

    def prepare!
      create_temp_directories
      write_riak_script
      write_vm_args
      write_app_config
    end

    private
    def create_temp_directories
      %w{bin etc log data}.each do |dir|
        instance_variable_set("@temp_#{dir}", File.expand_path(File.join(@temp_dir, dir)))
        FileUtils.mkdir_p(instance_variable_get("@temp_#{dir}"))
      end
    end

    def write_riak_script
      File.open(File.join(@temp_bin, 'riak'), 'wb') do |f|
        File.readlines(File.join(@bin_dir, 'riak')).each do |line|
          line.sub!(/(RUNNER_SCRIPT_DIR=)(.*)/, '\1' + @temp_bin)          
          line.sub!(/(RUNNER_ETC_DIR=)(.*)/, '\1' + @temp_etc)
          line.sub!(/(RUNNER_USER=)(.*)/, '\1' + @user)
          line.sub!(/(RUNNER_LOG_DIR=)(.*)/, '\1' + @temp_log)
          if line.strip == "RUNNER_BASE_DIR=${RUNNER_SCRIPT_DIR%/*}"
            line = "RUNNER_BASE_DIR=#{File.expand_path("..",@bin_dir)}"
          end
          f.write line + "\n"
        end
      end
    end

    def write_vm_args
      File.open(File.join(@temp_etc, 'vm.args'), 'wb') do |f|
        f.write @vm_args.map {|k,v| "#{k} #{v}" }.join("\n")
      end
    end

    def write_app_config
      File.open(File.join(@temp_etc, 'app.config'), 'wb') do |f|
        f.write to_erlang_config(@app_config) + '.'
      end
    end

    def deep_merge(source, target)
      source.merge(target) do |key, old_val, new_val|
        if Hash === old_val && Hash === new_val
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end

    def to_erlang_config(hash, depth = 1)
      padding = '    ' * depth
      parent_padding = '    ' * (depth-1)
      values = hash.map do |k,v|
        printable = case v
                    when Hash
                      to_erlang_config(v, depth+1)
                    when String
                      "\"#{v}\""
                    else
                      v.to_s
                    end
        "{#{k}, #{printable}}"
      end.join(",\n#{padding}")
      "[\n#{padding}#{values}\n#{parent_padding}]"
    end
  end
end
