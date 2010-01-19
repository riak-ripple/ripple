require File.join(File.dirname(__FILE__), "spec_helper")

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
