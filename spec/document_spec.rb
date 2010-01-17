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
require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Document do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, "foo")
    @document = Riak::Document.new(@bucket, "bar")
  end

  it "should match the JSON content type" do
    Riak::Document.should be_matches("content-type" => ["application/json"])
  end

  it "should match the YAML content type" do
    Riak::Document.should be_matches("content-type" => ["application/x-yaml"])
  end

  describe "when representing a JSON object" do
    before :each do
      @document.content_type = "application/json"
    end

    it "should serialize data as JSON" do
      @document.serialize({"foo" => "bar"}).should == '{"foo":"bar"}'
    end

    it "should deserialize data as JSON" do
      @document.deserialize('{"foo":"bar"}').should == {"foo" => "bar"}
    end
  end

  describe "when representing a YAML stream" do
    before :each do
      @document.content_type = "application/x-yaml"
    end

    it "should serialize data as YAML" do
      @document.serialize({"foo" => "bar"}).should == "--- \nfoo: bar\n"
    end

    it "should deserialize data as YAML" do
      @document.deserialize("--- \nfoo: bar\n").should == {"foo" => "bar"}
    end
  end

  describe "accessing properties of the data" do
    it "should delegate the bracket reader to the data" do
      @document.data = {"name" => "Riak"}
      @document["name"].should == "Riak"
    end

    it "should deleget the bracket setter to the data" do
      @document.data = {}
      @document["name"] = "Riak"
      @document.data.should == {"name" => "Riak"}
    end
  end
end
