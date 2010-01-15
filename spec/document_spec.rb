require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Document do
  it "should match the JSON content type" do
    Riak::Document.should be_matches("content-type" => ["application/json"])
  end

  it "should match the YAML content type" do
    Riak::Document.should be_matches("content-type" => ["application/x-yaml"])
  end
end
