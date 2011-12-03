$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
require 'rspec'
require 'fakeweb'

# Only the tests should really get away with this.
Riak.disable_list_keys_warnings = true

%w[integration_setup
   http_backend_implementation_examples
   unified_backend_examples
   mocks
   mock_server
   drb_mock_server
   test_server].each do |file|
  require File.join("support", file)
end

RSpec.configure do |config|
  #config.debug = true
  config.mock_with :rspec

  config.before(:all, :integration => true) do
    FakeWeb.allow_net_connect = true
  end

  config.after(:all, :integration => true) do
    FakeWeb.allow_net_connect = false
  end

  config.before(:each) do
    Riak::RObject.on_conflict_hooks.clear
    FakeWeb.clean_registry
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
