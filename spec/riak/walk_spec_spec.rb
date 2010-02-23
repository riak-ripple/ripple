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
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::WalkSpec do
  describe "initializing" do
    describe "with a hash" do
      it "should be empty by default" do
        spec = Riak::WalkSpec.new({})
        spec.bucket.should == "_"
        spec.tag.should == "_"
        spec.keep.should be_false
      end

      it "should extract the bucket" do
        spec = Riak::WalkSpec.new({:bucket => "foo"})
        spec.bucket.should == "foo"
        spec.tag.should == "_"
        spec.keep.should be_false
      end

      it "should extract the tag" do
        spec = Riak::WalkSpec.new({:tag => "foo"})
        spec.bucket.should == "_"
        spec.tag.should == "foo"
        spec.keep.should be_false
      end

      it "should extract the keep" do
        spec = Riak::WalkSpec.new({:keep => true})
        spec.bucket.should == "_"
        spec.tag.should == "_"
        spec.keep.should be_true
      end
    end

    describe "with three arguments for bucket, tag, and keep" do
      it "should assign the bucket, tag, and keep" do
        spec = Riak::WalkSpec.new("foo", "next", false)
        spec.bucket.should == "foo"
        spec.tag.should == "next"
        spec.keep.should be_false
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

      it "should make the keep false when false or nil" do
        spec = Riak::WalkSpec.new(nil, nil, nil)
        spec.keep.should be_false
        spec = Riak::WalkSpec.new(nil, nil, false)
        spec.keep.should be_false
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

    it "should include the keep when true" do
      @spec.keep = true
      @spec.to_s.should == "_,_,1"
    end
  end

  describe "creating from a list of parameters" do
    it "should detect hashes and WalkSpecs interleaved with other parameters" do
      specs = Riak::WalkSpec.normalize(nil,"next",nil,{:bucket => "foo"},Riak::WalkSpec.new({:tag => "child", :keep => true}))
      specs.should have(3).items
      specs.should be_all {|s| s.kind_of?(Riak::WalkSpec) }
      specs.join("/").should == "_,next,_/foo,_,_/_,child,1"
    end
  end

  describe "matching other objects with ===" do
    before :each do
      @spec = Riak::WalkSpec.new({})
    end

    it "should not match objects that aren't links or walk specs" do
      @spec.should_not === "foo"
    end

    describe "matching links" do
      before :each do
        @link = Riak::Link.new("/riak/foo/bar", "next")
      end

      it "should match a link when the bucket and tag are not specified" do
        @spec.should === @link
      end

      it "should match a link when the bucket is the same" do
        @spec.bucket = "foo"
        @spec.should === @link
      end

      it "should not match a link when the bucket is different" do
        @spec.bucket = "bar"
        @spec.should_not === @link
      end

      it "should match a link when the tag is the same" do
        @spec.tag = "next"
        @spec.should === @link
      end

      it "should not match a link when the tag is different" do
        @spec.tag = "previous"
        @spec.should_not === @link
      end

      it "should match a link when the bucket and tag are the same" do
        @spec.bucket = "foo"
        @spec.should === @link
      end
    end

    describe "matching walk specs" do
      before :each do
        @other = Riak::WalkSpec.new({})
      end

      it "should match a walk spec that is equivalent" do
        @spec.should === @other
      end

      it "should not match a walk spec that has a different keep value" do
        @other.keep = true
        @spec.should_not === @other
      end

      it "should match a walk spec with a more specific bucket" do
        @other.bucket = "foo"
        @spec.should === @other
      end

      it "should match a walk spec with the same bucket" do
        @other.bucket = "foo"; @spec.bucket = "foo"
        @spec.should === @other
      end

      it "should not match a walk spec with a different bucket" do
        @other.bucket = "foo"; @spec.bucket = "bar"
        @spec.should_not === @other
      end

      it "should match a walk spec with a more specific tag" do
        @other.tag = "next"
        @spec.should === @other
      end

      it "should match a walk spec with the same tag" do
        @other.tag = "next"; @spec.tag = "next"
        @spec.should === @other
      end

      it "should not match a walk spec with a different tag" do
        @other.tag = "next"; @spec.tag = "previous"
        @spec.should_not === @other
      end
    end
  end
end
