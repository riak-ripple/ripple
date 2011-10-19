require 'spec_helper'

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

    it "should keep the url intact if it does not point to a bucket or bucket/key" do
      result = Riak::Link.parse('</mapred>; rel="riak_kv_wm_mapred"')
      result[0].url.should == "/mapred"
      result[0].bucket.should be_nil
      result[0].key.should be_nil
    end

    it "should parse the Riak 1.0 URL scheme" do
      result = Riak::Link.parse('</buckets/b/keys/k>; riaktag="tag"').first
      result.bucket.should == 'b'
      result.key.should == 'k'
      result.tag.should == 'tag'
    end
  end

  context "converting to a string" do
    it "should convert to a string appropriate for use in the Link header" do
      Riak::Link.new("/riak/foo", "up").to_s.should == '</riak/foo>; riaktag="up"'
      Riak::Link.new("/riak/foo/bar", "next").to_s.should == '</riak/foo/bar>; riaktag="next"'
      Riak::Link.new("/riak", "riak_kv_wm_raw").to_s.should == '</riak>; riaktag="riak_kv_wm_raw"'
    end

    it "should convert to a string using the new URL scheme" do
      Riak::Link.new("bucket", "key", "tag").to_s(true).should == '</buckets/bucket/keys/key>; riaktag="tag"'
      Riak::Link.parse('</riak/bucket/key>; riaktag="tag"').first.to_s(true).should == '</buckets/bucket/keys/key>; riaktag="tag"'
    end
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

  it "should construct from bucket, key and tag" do
    link = Riak::Link.new("bucket", "key", "tag")
    link.bucket.should == "bucket"
    link.key.should == "key"
    link.tag.should == "tag"
    link.url.should == "/riak/bucket/key"
  end
end
