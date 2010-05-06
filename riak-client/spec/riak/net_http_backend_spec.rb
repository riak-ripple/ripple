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
require File.expand_path("../spec_helper", File.dirname(__FILE__))
                  
describe Riak::Client::NetHTTPBackend do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::NetHTTPBackend.new(@client)
    FakeWeb.allow_net_connect = false
  end

  def setup_http_mock(method, uri, options={})
    FakeWeb.register_uri(method, uri, options)
  end

  it_should_behave_like "HTTP backend"
end
