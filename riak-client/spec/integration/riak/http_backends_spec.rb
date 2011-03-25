# Copyright 2010 Sean Cribbs  and Basho Technologies, Inc.
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
require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe "HTTP" do
  before :all do
    if $test_server
      @web_port = 9000
      $test_server.start
    end
  end

  before do
    @web_port ||= 8098
    @client = Riak::Client.new(:port => @web_port)
  end

  after do
    $test_server.recycle if $test_server.started?
  end

  [:CurbBackend, :ExconBackend, :NetHTTPBackend].each do |klass|
    bklass = Riak::Client.const_get(klass)
    if bklass.configured?
      describe klass.to_s do
        before do
          @backend = bklass.new(@client)
        end

        it_should_behave_like "Unified backend API"
      end
    end
  end
end
