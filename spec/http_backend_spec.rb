require File.join(File.dirname(__FILE__), "spec_helper")

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
    @backend.default_headers.should == {"X-Riak-ClientId" => "testing"}
  end

  it "should generate a root URI based on the client settings" do
    @backend.root_uri.should be_kind_of(URI)
    @backend.root_uri.to_s.should == "http://127.0.0.1:8098/raw/"
    @client.prefix = "jiak"
    @backend.root_uri.to_s.should == "http://127.0.0.1:8098/jiak"
  end

  it "should compute a URI from a relative resource path" do
    @backend.path("baz").should be_kind_of(URI)
    @backend.path("foo").to_s.should == "http://127.0.0.1:8098/raw/foo"
    @backend.path("foo", "bar").to_s.should == "http://127.0.0.1:8098/raw/foo/bar"
    @backend.path("/foo/bar").to_s.should == "http://127.0.0.1:8098/raw/foo/bar"
  end

  it "should compute a URI from a relative resource path with a hash of query parameters" do
    @backend.path("baz", :r => 2).to_s.should == "http://127.0.0.1:8098/raw/baz?r=2"
  end

  it "should raise an error if a resource path is too short" do
    lambda { @backend.verify_path!([]) }.should raise_error(ArgumentError)
    lambda { @backend.verify_path!(["foo"]) }.should_not raise_error
  end

  describe "verify_path_and_body!" do
    it "should separate the path and body from given arguments" do
      uri, data = @backend.verify_path_and_body!(["foo", "This is the body."])
      uri.should == ["foo"]
      data.should == "This is the body."
    end

    it "should raise an error if the body is not a string" do
      lambda { @backend.verify_path_and_body!(["foo", nil]) }.should raise_error(ArgumentError)
    end

    it "should raise an error if a body is not given" do
      lambda { @backend.verify_path_and_body!(["foo"])}.should raise_error(ArgumentError)
    end

    it "should raise an error if a path is not given" do
      lambda { @backend.verify_path_and_body!([])}.should raise_error(ArgumentError)
    end
  end
end
