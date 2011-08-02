$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'riak-client','lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
%w{rails action_pack action_dispatch action_controller action_view}.each {|f| require f }
require 'riak-sessions'
require 'rspec'

%w[
  ripple_session_support
  rspec-rails-neuter
  test_server
].each do |file|
  require File.join("support", file)
end

RSpec.configure do |config|
  config.mock_with :rspec
end
