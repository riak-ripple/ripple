$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
require 'rspec'
require 'fakeweb'

# Only the tests should really get away with this.
Riak.disable_list_keys_warnings = true

begin
  require 'yaml'
  require 'riak/test_server'
  config = YAML.load_file("spec/support/test_server.yml")
  $test_server = Riak::TestServer.new(config.symbolize_keys)
  $test_server.prepare!
  $test_server.start
  at_exit { $test_server.cleanup }
rescue => e
  warn "Can't run Riak::TestServer specs. Specify the location of your Riak installation in spec/support/test_server.yml. See Riak::TestServer docs for more info."
  warn e.inspect
end

Dir[File.join(File.dirname(__FILE__), "support", "*.rb")].sort.each {|f| require f }


RSpec.configure do |config|
  config.debug = true
  config.mock_with :rspec
  
  config.before(:each) do
    Riak::RObject.on_conflict_hooks.clear
    FakeWeb.clean_registry
  end

  config.after(:suite) do
    if errors = $test_server.console_log(:error)
      warn "\n\nRiak console log errors:"
      errors.each { |e| warn "  " + e.chomp }
    end
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
