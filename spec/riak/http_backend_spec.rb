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
#    limitations under the License
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::Client::HTTPBackend do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::HTTPBackend.new(@client)
  end

  it "should take the Riak::Client when creating" do
    lambda { Riak::Client::HTTPBackend.new(nil) }.should raise_error(ArgumentError)
    lambda { Riak::Client::HTTPBackend.new(@client) }.should_not raise_error
  end

  it "should make the client accessible" do
    @backend.client.should == @client
  end

  it "should generate default headers for requests based on the client settings" do
    @client.client_id = "testing"
    @backend.default_headers.should == {"X-Riak-ClientId" => "testing", "Accept" => "multipart/mixed, application/json;q=0.7, */*;q=0.5"}
  end

  it "should generate a root URI based on the client settings" do
    @backend.root_uri.should be_kind_of(URI)
    @backend.root_uri.to_s.should == "http://127.0.0.1:8098"
  end

  it "should compute a URI from a relative resource path" do
    @backend.path("baz").should be_kind_of(URI)
    @backend.path("foo").to_s.should == "http://127.0.0.1:8098/foo"
    @backend.path("foo", "bar").to_s.should == "http://127.0.0.1:8098/foo/bar"
    @backend.path("/foo/bar").to_s.should == "http://127.0.0.1:8098/foo/bar"
  end

  it "should compute a URI from a relative resource path with a hash of query parameters" do
    @backend.path("baz", :r => 2).to_s.should == "http://127.0.0.1:8098/baz?r=2"
  end

  it "should raise an error if a resource path is too short" do
    lambda { @backend.verify_path!(["/riak/"]) }.should raise_error(ArgumentError)
    lambda { @backend.verify_path!(["/riak/", "foo"]) }.should_not raise_error
    lambda { @backend.verify_path!(["/mapred"]) }.should_not raise_error
  end

  describe "verify_path_and_body!" do
    it "should separate the path and body from given arguments" do
      uri, data = @backend.verify_path_and_body!(["/riak/", "foo", "This is the body."])
      uri.should == ["/riak/", "foo"]
      data.should == "This is the body."
    end

    it "should raise an error if the body is not a string or IO" do
      lambda { @backend.verify_path_and_body!(["/riak/", "foo", nil]) }.should raise_error(ArgumentError)
      lambda { @backend.verify_path_and_body!(["/riak/", "foo", File.open("spec/fixtures/cat.jpg")]) }.should_not raise_error(ArgumentError)
    end

    it "should raise an error if a body is not given" do
      lambda { @backend.verify_path_and_body!(["/riak/", "foo"])}.should raise_error(ArgumentError)
    end

    it "should raise an error if a path is not given" do
      lambda { @backend.verify_path_and_body!(["/riak/"])}.should raise_error(ArgumentError)
    end
  end
  
  describe "detecting valid response codes" do
    it "should accept strings or integers for either argument" do
      @backend.should be_valid_response("300", "300")
      @backend.should be_valid_response(300, "300")
      @backend.should be_valid_response("300", 300)
    end

    it "should accept an array of strings or integers for the expected code" do
      @backend.should be_valid_response([200,304], "200")
      @backend.should be_valid_response(["200",304], "200")
      @backend.should be_valid_response([200,"304"], "200")
      @backend.should be_valid_response(["200","304"], "200")
      @backend.should be_valid_response([200,304], 200)
    end

    it "should be false when none of the response codes match" do
      @backend.should_not be_valid_response(200, 404)
      @backend.should_not be_valid_response(["200","304"], 404)
      @backend.should_not be_valid_response([200,304], 404)
    end
  end

  describe "detecting whether a body should be returned" do
    it "should be false when the method is :head" do
      @backend.should_not be_return_body(:head, 200, false)
    end

    it "should be false when the response code is 204, 205, or 304" do
      @backend.should_not be_return_body(:get, 204, false)
      @backend.should_not be_return_body(:get, 205, false)
      @backend.should_not be_return_body(:get, 304, false)
    end

    it "should be false when a streaming block was passed" do
      @backend.should_not be_return_body(:get, 200, true)
    end

    it "should be true when the method is not head, a code other than 204, 205, or 304 was given, and there was no streaming block" do
      [:get, :put, :post, :delete].each do |method|
        [100,101,200,201,202,203,206,300,301,302,303,305,307,400,401,
         402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,
         500,501,502,503,504,505].each do |code|
          @backend.should be_return_body(method, code, false)
          @backend.should be_return_body(method, code.to_s, false)
        end
      end
    end
  end
  
  it "should force subclasses to implement the perform method" do
    lambda { @backend.send(:perform, :get, "/foo", {}, 200) }.should raise_error(NotImplementedError)
  end
end
