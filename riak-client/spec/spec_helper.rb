# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
require 'rspec'
require 'fakeweb'

begin
  require 'yaml'
  config = YAML.load_file("spec/support/test_server.yml")
  $test_server = Riak::TestServer.new(config.symbolize_keys)
  $test_server.prepare!
  $test_server.start
  at_exit { $test_server.cleanup }
rescue => e
  warn "Can't run Riak::TestServer specs. Specify the location of your Riak installation in spec/support/test_server.yml. See Riak::TestServer docs for more info."
  warn e.inspect
end

Dir[File.join(File.dirname(__FILE__), "support", "*.rb")].each {|f| require f }

Rspec.configure do |config|
  config.mock_with :rspec

  config.before(:each) do
    FakeWeb.clean_registry
  end
end
