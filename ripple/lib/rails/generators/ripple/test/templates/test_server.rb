require 'riak/test_server'

module Ripple  
  module TestServer
    extend self

    # Tweak this to change how your test server is configured
    def test_server_config
      {
        :app_config => {
          :riak_kv => {
            :js_source_dir => Ripple.config.delete(:js_source_dir),
            :map_cache_size => 0, # 0.14
            :vnode_cache_entries => 0 # 0.13
          },
          :riak_core => { :web_port => Ripple.config[:port] || 8098 }
        },
        :bin_dir => Ripple.config.delete(:bin_dir),
        :temp_dir => Rails.root + "tmp/riak_test_server"
      }
    end

    # Prepares the subprocess Riak node for the test suite
    def setup
      unless @test_server
        begin
          _server = @test_server = Riak::TestServer.new(test_server_config)
          @test_server.prepare!
          @test_server.start
          at_exit { _server.cleanup }
        rescue => e
          warn "Can't run tests with Riak::TestServer. Specify the location of your Riak installation in the config/ripple.yml #{Rails.env} environment."
          warn e.inspect
          @test_server = nil
        end
      end
    end

    # Clear the data after each test run
    def clear
      @test_server.recycle if @test_server
    end
  end
end

Ripple::TestServer.setup
