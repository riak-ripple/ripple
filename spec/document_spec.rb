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

    it "should serialize data as JSON" do
      @document.serialize({"foo" => "bar"}).should == "--- \nfoo: bar\n"
    end

    it "should deserialize data as JSON" do
      @document.deserialize("--- \nfoo: bar\n").should == {"foo" => "bar"}
    end
  end
end
