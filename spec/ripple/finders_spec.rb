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
require File.expand_path("../../spec_helper", __FILE__)

describe Ripple::Document::Finders do
  before :all do
    class Box
      include Ripple::Document
      property :shape, String
    end
  end

  before :each do
    @http = mock("HTTP Backend")
    @client = Ripple.client
    @client.stub!(:http).and_return(@http)
    @bucket = Riak::Bucket.new(@client, "boxes")
    @client.stub!(:[]).and_return(@bucket)
  end

  describe "finding single documents" do
    it "should find a single document by key and assign its attributes" do
      @http.should_receive(:get).with(200, "/raw/", "boxes", "square", {}, {}).and_return({:code => 200, :headers => {"content-type" => ["application/json"]}, :body => '{"shape":"square"}'})
      box = Box.find("square")
      box.should be_kind_of(Box)
      box.shape.should == "square"
      box.key.should == "square"
    end

    it "should return nil when no object exists at that key" do
      @http.should_receive(:get).with(200, "/raw/", "boxes", "square", {}, {}).and_raise(Riak::FailedRequest.new(:get, 200, 404, {}, "404 not found"))
      box = Box.find("square")
      box.should be_nil
    end

    it "should re-raise the failed request exception if not a 404" do
      @http.should_receive(:get).with(200, "/raw/", "boxes", "square", {}, {}).and_raise(Riak::FailedRequest.new(:get, 200, 500, {}, "500 internal server error"))
      lambda { Box.find("square") }.should raise_error(Riak::FailedRequest)
    end
  end

  after :all do
    Object.send(:remove_const, :Box)
  end
end
