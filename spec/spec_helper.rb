$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'riak-client'
require 'spec'
require 'spec/autorun'

Dir[File.join(File.dirname(__FILE__), "support", "*.rb")].each {|f| require f }

Spec::Runner.configure do |config|

end
