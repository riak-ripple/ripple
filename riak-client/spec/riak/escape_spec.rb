
require 'spec_helper'

describe Riak::Util::Escape do
  before :each do
    @object = Object.new
    @object.extend(Riak::Util::Escape)
  end

  it "should use URI by default for escaping" do
    Riak.escaper.should == URI
  end

  context "when using CGI for escaping" do
    before { @oldesc, Riak.escaper = Riak.escaper, CGI }
    after { Riak.escaper = @oldesc }

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

  context "when using URI for escaping" do
    before { @oldesc, Riak.escaper = Riak.escaper, URI }
    after { Riak.escaper = @oldesc }

    it "should escape standard non-safe characters" do
      @object.escape("some string").should == "some%20string"
      @object.escape("another^one").should == "another%5Eone"
    end

    it "should allow URI-safe characters" do
      @object.escape("bracket[one").should == "bracket[one"
      @object.escape("sean@basho").should == "sean@basho"
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
end
