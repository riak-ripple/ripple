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
require File.expand_path('../../spec_helper', __FILE__)

describe "Search mixins" do
  before :all do
    require 'riak/search'
  end

  describe Riak::MapReduce do
    before :each do
      @client = Riak::Client.new
      @mr = Riak::MapReduce.new(@client)
    end

    describe "using a search query as inputs" do
      it "should accept a bucket name and query" do
        @mr.search("foo", "bar OR baz")
        @mr.inputs.should == {:module => "riak_search", :function => "mapred_search", :arg => ["foo", "bar OR baz"]}
      end

      it "should accept a Riak::Bucket and query" do
        @mr.search(Riak::Bucket.new(@client, "foo"), "bar OR baz")
        @mr.inputs.should == {:module => "riak_search", :function => "mapred_search", :arg => ["foo", "bar OR baz"]}
      end
      
      it "should emit the Erlang function and arguments" do
        @mr.search("foo", "bar OR baz")
        @mr.to_json.should include('"inputs":{')
        @mr.to_json.should include('"module":"riak_search"')
        @mr.to_json.should include('"function":"mapred_search"')
        @mr.to_json.should include('"arg":["foo","bar OR baz"]')
      end
    end
  end
end
