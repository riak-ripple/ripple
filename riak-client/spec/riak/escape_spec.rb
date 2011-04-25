
require File.expand_path("../../spec_helper", __FILE__)

describe Riak::Util::Escape do
  before :each do
    @object = Object.new
    @object.extend(Riak::Util::Escape)
  end

  it "should escape standard non-safe characters" do
    @object.escape("some string").should == "some%20string"
    @object.escape("another^one").should == "another%5Eone"
    @object.escape("bracket[one").should == "bracket%5Bone"
  end

  it "should escape slashes" do
    @object.escape("some/inner/path").should == "some%2Finner%2Fpath"
  end
  
  it "should convert the bucket or key to a string before escaping" do
    @object.escape(125).should == '125'
  end

  it "should unescape escaped strings" do
    @object.unescape("some%20string").should == "some string"
    @object.unescape("another%5Eone").should == "another^one"
    @object.unescape("bracket%5Bone").should == "bracket[one"
    @object.unescape("some%2Finner%2Fpath").should == "some/inner/path"
  end
end
