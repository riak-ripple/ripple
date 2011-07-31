$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
require 'rspec'
require 'fakeweb'

# Only the tests should really get away with this.
Riak.disable_list_keys_warnings = true

Dir[File.join(File.dirname(__FILE__), "support", "*.rb")].sort.each {|f| require f }

RSpec.configure do |config|
  config.debug = true
  config.mock_with :rspec

  config.before(:each, :integration => true) do
    begin
      unless $test_server
        require 'riak/test_server'
        config = YAML.load_file("spec/support/test_server.yml")
        $test_server = Riak::TestServer.create(:root => config['root'],
                                               :source => config['source'],
                                               :min_port => 15000)
        at_exit { $test_server.stop }
      end
      if example.metadata[:test_server] == false
        $test_server.stop
      else
        $test_server.start
      end
    rescue => e
      warn "Can't run integration specs without the test server. Please create spec/support/test_server.yml."
      warn e.inspect
    end
  end

  config.after(:each, :integration => true) do
    $test_server.drop if $test_server && $test_server.started?
  end

  config.before(:each) do
    Riak::RObject.on_conflict_hooks.clear
    FakeWeb.clean_registry
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
