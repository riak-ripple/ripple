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
      result = Riak::Link.parse('</riak/foo/bar>; rel="tag", </riak/foo>; rel="up"')
      result.should be_kind_of(Array)
      result.should be_all {|i| Riak::Link === i }
    end

    it "should set the bucket, key, url and rel parameters properly" do
      result = Riak::Link.parse('</riak/foo/bar>; riaktag="tag", </riak/foo>; rel="up"')
      result[0].url.should == "/riak/foo/bar"
      result[0].bucket.should == "foo"
      result[0].key.should == "bar"
      result[0].rel.should == "tag"
      result[1].url.should == "/riak/foo"
      result[1].bucket.should == "foo"
      result[1].key.should == nil
      result[1].rel.should == "up"
    end
    
    it "should set url properly, and set bucket and key to nil for non-Riak links" do
      result = Riak::Link.parse('<http://www.example.com/123.html>; riaktag="tag", </riak/foo>; rel="up"')
      result[0].url.should == "http://www.example.com/123.html"
      result[0].bucket.should == nil
      result[0].key.should == nil
      result[0].rel.should == "tag"

      result = Riak::Link.parse('<http://www.example.com/>; riaktag="tag", </riak/foo>; rel="up"')
      result[0].url.should == "http://www.example.com/"
      result[0].bucket.should == nil
      result[0].key.should == nil
      result[0].rel.should == "tag"
    end
  end

  it "should convert to a string appropriate for use in the Link header" do
    Riak::Link.new("/riak/foo", "up").to_s.should == '</riak/foo>; riaktag="up"'
    Riak::Link.new("/riak/foo/bar", "next").to_s.should == '</riak/foo/bar>; riaktag="next"'
  end

  it "should convert to a walk spec when pointing to an object" do
    Riak::Link.new("/riak/foo/bar", "next").to_walk_spec.to_s.should == "foo,next,_"
    lambda { Riak::Link.new("/riak/foo", "up").to_walk_spec }.should raise_error
  end

  it "should be equivalent to a link with the same url and rel" do
    one = Riak::Link.new("/riak/foo/bar", "next")
    two = Riak::Link.new("/riak/foo/bar", "next")
    one.should == two
    [one].should include(two)
    [two].should include(one)
  end

  it "should unescape the bucket name" do
    Riak::Link.new("/riak/bucket%20spaces/key", "foo").bucket.should == "bucket spaces"
  end

  it "should unescape the key name" do
    Riak::Link.new("/riak/bucket/key%2Fname", "foo").key.should == "key/name"
  end

  it "should not rely on the prefix to equal /riak/ when extracting the bucket and key" do
    link = Riak::Link.new("/raw/bucket/key", "foo")
    link.bucket.should == "bucket"
    link.key.should == "key"
  end
end
