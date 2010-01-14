$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'ripple'
require 'spec'
require 'spec/autorun'
require 'fakeweb'

Dir[File.join(File.dirname(__FILE__), "support", "*.rb")].each {|f| require f }

$server = MockServer.new
at_exit { $server.stop }

Spec::Runner.configure do |config|
  config.before(:each) do
    FakeWeb.clean_registry
  end
end
