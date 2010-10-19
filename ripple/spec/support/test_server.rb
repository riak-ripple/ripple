require 'riak/test_server'

unless $test_server
  begin    
    require 'yaml'
    config = YAML.load_file("spec/support/test_server.yml")
    $test_server = Riak::TestServer.new(config.symbolize_keys)
    $test_server.prepare!
    $test_server.start
    Ripple.config = {:port => 9000 }
    at_exit { $test_server.cleanup }
  rescue => e
    warn "Can't run Riak::TestServer specs. Specify the location of your Riak installation in spec/support/test_server.yml. See Riak::TestServer docs for more info."
    warn e.inspect
    $test_server = nil
  end
end
