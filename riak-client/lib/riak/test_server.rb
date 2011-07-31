require 'riak/node'

if ENV['DEBUG_RIAK_TEST_SERVER']
  $expect_verbose = true
end

module Riak
  # The TestServer is a special {Node} that uses in-memory storage
  # engines that are easily cleared. This is helpful when running test
  # suites that store and retrieve objects from Riak and expect a
  # clean-slate at the beginning of each test. Like {Node}, creation
  # is idempotent, so you can keep the server around between runs of
  # your test suite.
  class TestServer < Node
    # Creates a TestServer node, using in-memory backends for KV and Search.
    def initialize(configuration = {})
      configuration[:env] ||= {}
      configuration[:env][:riak_kv] ||= {}
      (configuration[:env][:riak_kv][:add_paths] ||= []) << File.expand_path("../../../erl_src", __FILE__)
      configuration[:env][:riak_kv][:storage_backend] = :riak_kv_test_backend
      configuration[:env][:riak_search] ||= {}
      configuration[:env][:riak_search][:search_backend] = :riak_search_test_backend
      super configuration      
    end

    def start
      super
      @console = attach
    end

    def stop
      @console.close unless @console.frozen?
      super
    end
    
    # Overrides the default {Node#drop} to simply clear the in-memory
    # backends.
    def drop
      @console = attach if @console.frozen?
      @console.command "riak_kv_test_backend:reset()."
      @console.command "riak_search_test_backend:reset()."
    end
  end
end
