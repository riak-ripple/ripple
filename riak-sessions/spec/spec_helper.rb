$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'riak-client','lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
%w{rails action_pack action_dispatch action_controller action_view}.each {|f| require f }
require 'riak-sessions'
require 'rspec'

Dir[File.join(File.dirname(__FILE__), "support", "*.rb")].each {|f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:each) do
    $test_server.recycle if $test_server
  end
end
