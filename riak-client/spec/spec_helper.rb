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

  config.before(:each) do
    Riak::RObject.on_conflict_hooks.clear
    FakeWeb.clean_registry
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
