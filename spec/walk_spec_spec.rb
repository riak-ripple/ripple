require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::WalkSpec do
  describe "initializing" do
    describe "with a hash" do
      it "should be empty by default" do
        spec = Riak::WalkSpec.new({})
        spec.bucket.should == "_"
        spec.tag.should == "_"
        spec.result.should be_false
      end

      it "should extract the bucket" do
        spec = Riak::WalkSpec.new({:bucket => "foo"})
        spec.bucket.should == "foo"
        spec.tag.should == "_"
        spec.result.should be_false
      end

      it "should extract the tag" do
        spec = Riak::WalkSpec.new({:tag => "foo"})
        spec.bucket.should == "_"
        spec.tag.should == "foo"
        spec.result.should be_false
      end

      it "should extract the result" do
        spec = Riak::WalkSpec.new({:result => true})
        spec.bucket.should == "_"
        spec.tag.should == "_"
        spec.result.should be_true
      end
    end

    describe "with three arguments for bucket, tag, and result" do
      it "should assign the bucket, tag, and result" do
        spec = Riak::WalkSpec.new("foo", "next", false)
        spec.bucket.should == "foo"
        spec.tag.should == "next"
        spec.result.should be_false
      end

      it "should make the bucket '_' when false or nil" do
        spec = Riak::WalkSpec.new(nil, "next", false)
        spec.bucket.should == "_"
        spec = Riak::WalkSpec.new(false, "next", false)
        spec.bucket.should == "_"
      end

      it "should make the tag '_' when false or nil" do
        spec = Riak::WalkSpec.new("foo", nil, false)
        spec.tag.should == "_"
        spec = Riak::WalkSpec.new("foo", false, false)
        spec.tag.should == "_"
      end

      it "should make the result false when false or nil" do
        spec = Riak::WalkSpec.new(nil, nil, nil)
        spec.result.should be_false
        spec = Riak::WalkSpec.new(nil, nil, false)
        spec.result.should be_false
      end
    end

    it "should raise an ArgumentError for invalid arguments" do
      lambda { Riak::WalkSpec.new }.should raise_error(ArgumentError)
      lambda { Riak::WalkSpec.new("foo") }.should raise_error(ArgumentError)
      lambda { Riak::WalkSpec.new("foo","bar") }.should raise_error(ArgumentError)
    end
  end

  describe "converting to a string" do
    before :each do
      @spec = Riak::WalkSpec.new({})
    end

    it "should be the empty spec by default" do
      @spec.to_s.should == "_,_,_"
    end

    it "should include the bucket when set" do
      @spec.bucket = "foo"
      @spec.to_s.should == "foo,_,_"
    end

    it "should include the tag when set" do
      @spec.tag = "next"
      @spec.to_s.should == "_,next,_"
    end

    it "should include the result when true" do
      @spec.result = true
      @spec.to_s.should == "_,_,1"
    end
  end
end
