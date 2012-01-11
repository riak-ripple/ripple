require 'riak/test_server'
require 'singleton'

module Ripple
  # Extends the {Riak::TestServer} to be aware of the Ripple
  # configuration and adjust settings appropriately. Also simplifies
  # its usage in the generation of test helpers.
  class TestServer < Riak::TestServer
    include Singleton

    # Creates and starts the test server
    def self.setup
      instance.create
      instance.start
    end

    # Clears data from the test server
    def self.clear
      instance.drop
    end

    # @private
    def initialize(options=Ripple.config.dup)
      options[:env] ||= {}
      options[:env][:riak_kv] ||= {}
      options[:env][:riak_kv][:js_source_dir] ||= Ripple.config.delete(:js_source_dir)
      options[:env][:riak_kv][:map_cache_size] ||= 0
      options[:env][:riak_core] ||= {}
      options[:env][:riak_core][:http] ||= [ Tuple[Ripple.config[:host], Ripple.config[:http_port]] ]
      options[:env][:riak_kv][:pb_port] ||= Ripple.config[:pb_port]
      options[:env][:riak_kv][:pb_ip] ||= Ripple.config[:host]
      super(options)
    end
  end
end
