# Copyright 2010-2011 Sean Cribbs and Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'riak/test_server'

unless $test_server
  begin    
    require 'yaml'
    config = YAML.load_file("spec/support/test_server.yml")
    $test_server = Riak::TestServer.new(config.symbolize_keys)
    $test_server.prepare!
    $test_server.start
    Ripple.config = {:http_port => 9000 }
    at_exit { $test_server.cleanup }
  rescue => e
    warn "Can't run Riak::TestServer specs. Specify the location of your Riak installation in spec/support/test_server.yml. See Riak::TestServer docs for more info."
    warn e.inspect
    $test_server = nil
  end
end
