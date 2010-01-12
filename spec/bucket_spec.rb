require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Bucket do
  before :each do
    @client = Riak::Client.new
  end

  describe "when initializing" do
    it "should require a client and a name" do
      lambda { Riak::Bucket.new }.should raise_error
      lambda { Riak::Bucket.new(@client) }.should raise_error
      lambda { Riak::Bucket.new("foo") }.should raise_error
      lambda { Riak::Bucket.new("foo", @client) }.should raise_error
      lambda { Riak::Bucket.new(@client, "foo") }.should_not raise_error
    end
  end

  describe "when loading data from an HTTP response" do
    before :each do
      @bucket = Riak::Bucket.new(@client, "foo")
    end

    def do_load(overrides={})
      @bucket.load({
                     :body => '{"props":{"name":"foo","allow_mult":false,"big_vclock":50,"chash_keyfun":{"mod":"riak_util","fun":"chash_std_keyfun"},"linkfun":{"mod":"jiak_object","fun":"mapreduce_linkfun"},"n_val":3,"old_vclock":86400,"small_vclock":10,"young_vclock":20},"keys":["bar"]}',
                     :headers => {
                       "vary" => ["Accept-Encoding"],
                       "server" => ["MochiWeb/1.1 WebMachine/1.5.1 (hack the charles gibson)"],
                       "link" => ['</raw/foo/bar>; riaktag="contained"'],
                       "date" => ["Tue, 12 Jan 2010 15:30:43 GMT"],
                       "content-type" => ["application/json"],
                       "content-length" => ["257"]
                     }
                   }.merge(overrides))
    end
    
    it "should load the bucket properties from the response body" do
      do_load
      @bucket.props.should == {"name"=>"foo","allow_mult" => false,"big_vclock" => 50,"chash_keyfun" => {"mod" =>"riak_util","fun"=>"chash_std_keyfun"},"linkfun"=>{"mod"=>"jiak_object","fun"=>"mapreduce_linkfun"},"n_val"=>3,"old_vclock"=>86400,"small_vclock"=>10,"young_vclock"=>20}
    end
    
    it "should load the keys from the response body" do
      do_load
      @bucket.keys.should == ["bar"]
    end
    
    it "should ignore a response that is not JSON" do
      do_load(:headers => {"content-type" => ["text/plain"]})
      @bucket.props.should be_blank
      @bucket.keys.should be_blank
    end
  end
end
