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

describe Riak::Util::Headers do
  it "should include the Net::HTTPHeader module" do
    Riak::Util::Headers.included_modules.should include(Net::HTTPHeader)
  end

  it "should be initially empty" do
    Riak::Util::Headers.new.to_hash.should == {}
  end

  it "should parse a header line into the key and value" do
    Riak::Util::Headers.parse("Content-Type: text/plain\n").should == ["Content-Type", "text/plain"]
  end

  it "should parse a header line and add it to the collection" do
    h = Riak::Util::Headers.new
    h.parse("Content-Type: text/plain\n")
    h.to_hash.should == {"content-type" => ["text/plain"]}
  end
end
