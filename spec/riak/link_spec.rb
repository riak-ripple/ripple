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

describe Riak::Link do
  describe "parsing a link header" do
    it "should create Link objects from the data" do
      result = Riak::Link.parse('</raw/foo/bar>; rel="tag", </raw/foo>; rel="up"')
      result.should be_kind_of(Array)
      result.should be_all {|i| Riak::Link === i }
    end

    it "should set the bucket, key, url and rel parameters properly" do
      result = Riak::Link.parse('</raw/foo/bar>; riaktag="tag", </raw/foo>; rel="up"')
      result[0].url.should == "/raw/foo/bar"
      result[0].bucket.should == "foo"
      result[0].key.should == "bar"
      result[0].rel.should == "tag"
      result[1].url.should == "/raw/foo"
      result[1].bucket.should == nil
      result[1].key.should == nil
      result[1].rel.should == "up"
    end
    
  end

  it "should convert to a string appropriate for use in the Link header" do
    Riak::Link.new("/raw/foo", "up").to_s.should == '</raw/foo>; riaktag="up"'
    Riak::Link.new("/raw/foo/bar", "next").to_s.should == '</raw/foo/bar>; riaktag="next"'
  end

  it "should convert to a walk spec when pointing to an object" do
    Riak::Link.new("/raw/foo/bar", "next").to_walk_spec.to_s.should == "foo,next,_"
    lambda { Riak::Link.new("/raw/foo", "up").to_walk_spec }.should raise_error
  end

  it "should be equivalent to a link with the same url and rel" do
    one = Riak::Link.new("/raw/foo/bar", "next")
    two = Riak::Link.new("/raw/foo/bar", "next")
    one.should == two
    [one].should include(two)
    [two].should include(one)
  end
end
