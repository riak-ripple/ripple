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

describe Riak::Bucket do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, "foo")
  end

  def do_load(overrides={})
    @bucket.load({
                   :body => '{"props":{"name":"foo","n_val":3,"allow_mult":false,"last_write_wins":false,"precommit":[],"postcommit":[],"chash_keyfun":{"mod":"riak_core_util","fun":"chash_std_keyfun"},"linkfun":{"mod":"riak_kv_wm_link_walker","fun":"mapreduce_linkfun"},"old_vclock":86400,"young_vclock":20,"big_vclock":50,"small_vclock":10,"r":"quorum","w":"quorum","dw":"quorum","rw":"quorum"},"keys":["bar"]}',
                   :headers => {
                     "vary" => ["Accept-Encoding"],
                     "server" => ["MochiWeb/1.1 WebMachine/1.5.1 (hack the charles gibson)"],
                     "link" => ['</riak/foo/bar>; riaktag="contained"'],
                     "date" => ["Tue, 12 Jan 2010 15:30:43 GMT"],
                     "content-type" => ["application/json"],
                     "content-length" => ["257"]
                   }
                 }.merge(overrides))
  end


  describe "when initializing" do
    it "should require a client and a name" do
      lambda { Riak::Bucket.new }.should raise_error
      lambda { Riak::Bucket.new(@client) }.should raise_error
      lambda { Riak::Bucket.new("foo") }.should raise_error
      lambda { Riak::Bucket.new("foo", @client) }.should raise_error
      lambda { Riak::Bucket.new(@client, "foo") }.should_not raise_error
    end

    it "should set the client and name attributes" do
      bucket = Riak::Bucket.new(@client, "foo")
      bucket.client.should == @client
      bucket.name.should == "foo"
    end
  end

  describe "when loading data from an HTTP response" do
    it "should load the bucket properties from the response body" do
      do_load
      @bucket.props.should == {"name"=>"foo", "n_val"=>3, "allow_mult"=>false, "last_write_wins"=>false, "precommit"=>[], "postcommit"=>[], "chash_keyfun"=>{"mod"=>"riak_core_util", "fun"=>"chash_std_keyfun"}, "linkfun"=>{"mod"=>"riak_kv_wm_link_walker", "fun"=>"mapreduce_linkfun"}, "old_vclock"=>86400, "young_vclock"=>20, "big_vclock"=>50, "small_vclock"=>10, "r"=>"quorum", "w"=>"quorum", "dw"=>"quorum", "rw"=>"quorum"}
    end

    it "should load the keys from the response body" do
      do_load
      @bucket.keys.should == ["bar"]
    end

    it "should raise an error for a response that is not JSON" do
      lambda do
        do_load(:headers => {"content-type" => ["text/plain"]})
      end.should raise_error(Riak::InvalidResponse)
    end

    it "should unescape key names" do
      do_load(:body => '{"keys":["foo", "bar%20baz"]}')
      @bucket.keys.should == ["foo", "bar baz"]
    end
  end

  describe "accessing keys" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
    end

    it "should load the keys if not present" do
      @http.should_receive(:get).with(200, "/riak/", "foo", {:props => false, :keys => true}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"keys":["bar"]}'})
      @bucket.keys.should == ["bar"]
    end

    it "should allow reloading of the keys" do
      @http.should_receive(:get).with(200, "/riak/","foo", {:props => false, :keys => true}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"keys":["bar"]}'})
      do_load # Ensures they're already loaded
      @bucket.keys(:reload => true).should == ["bar"]
    end

    it "should allow streaming keys through block" do
      # pending "Needs support in the raw_http_resource"
      @http.should_receive(:get).with(200, "/riak/","foo", {:props => false, :keys => "stream"}, {}).and_yield("{}").and_yield('{"keys":[]}').and_yield('{"keys":["bar"]}').and_yield('{"keys":["baz"]}')
      all_keys = []
      @bucket.keys do |list|
        all_keys.concat(list)
      end
      all_keys.should == ["bar", "baz"]
    end

    it "should unescape key names" do
      @http.should_receive(:get).with(200, "/riak/","foo", {:props => false, :keys => true}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"keys":["bar%20baz"]}'})
      @bucket.keys.should == ["bar baz"]
    end

    it "should escape the bucket name" do
      @bucket.instance_variable_set :@name, "unescaped "
      @http.should_receive(:get).with(200, "/riak/","unescaped%20", {:props => false, :keys => true}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"keys":["bar"]}'})
      @bucket.keys.should == ["bar"]
    end
  end

  describe "setting the bucket properties" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
    end

    it "should PUT the new properties to the bucket" do
      @http.should_receive(:put).with(204, "/riak/","foo", '{"props":{"name":"foo"}}', {"Content-Type" => "application/json"}).and_return({:body => "", :headers => {}})
      @bucket.props = { :name => "foo" }
    end

    it "should raise an error if an invalid property is given" do
      lambda { @bucket.props = "blah" }.should raise_error(ArgumentError)
    end

    it "should escape the bucket name" do
      @bucket.instance_variable_set :@name, "foo bar"
      @http.should_receive(:put).with(204, "/riak/","foo%20bar", '{"props":{"n_val":2}}', {"Content-Type" => "application/json"}).and_return({:body => "", :headers => {}})
      @bucket.props = {:n_val => 2}
    end
  end

  describe "fetching an object" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
    end

    it "should load the object from the server as a Riak::RObject" do
      @http.should_receive(:get).with(200, "/riak/","foo", "db", {}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'})
      @bucket.get("db").should be_kind_of(Riak::RObject)
    end

    it "should use the given query parameters (for R value, etc)" do
      @http.should_receive(:get).with(200, "/riak/","foo", "db", {:r => 2}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'})
      @bucket.get("db", :r => 2).should be_kind_of(Riak::RObject)
    end

    it "should allow 300 responses if allow_mult is set" do
      @bucket.instance_variable_set(:@props, {'allow_mult' => true})
      @http.should_receive(:get).with([200,300], "/riak/","foo", "db", {}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'})
      @bucket.get('db')
    end

    it "should escape the bucket and key names" do
      @bucket.instance_variable_set(:@name, "foo ")
      @http.should_receive(:get).with(200, "/riak/","foo%20", "%20bar", {}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'})
      @bucket.get(' bar')
    end
  end

  describe "creating a new blank object" do
    it "should instantiate the object with the given key, default to JSON" do
      obj = @bucket.new('bar')
      obj.should be_kind_of(Riak::RObject)
      obj.key.should == 'bar'
      obj.content_type.should == 'application/json'
    end
  end

  describe "fetching or creating a new object" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
    end

    it "should return the existing object if present" do
      @http.should_receive(:get).with(200, "/riak/","foo", "db", {}, {}).and_return({:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'})
      obj = @bucket.get_or_new('db')
      obj.key.should == 'db'
      obj.data['name'].should == "Riak"
    end

    it "should create a new blank object if the key does not exist" do
      @http.should_receive(:get).and_raise(Riak::FailedRequest.new(:get, 200, 404, {}, "File not found"))
      obj = @bucket.get_or_new('db')
      obj.key.should == 'db'
      obj.data.should be_blank
    end

    it "should bubble up non-ok non-missing errors" do
      @http.should_receive(:get).and_raise(Riak::FailedRequest.new(:get, 200, 500, {}, "File not found"))
      lambda { @bucket.get_or_new('db') }.should raise_error(Riak::FailedRequest)
    end
  end

  describe "get/set allow_mult property" do
    before :each do
      do_load
    end

    it "should extract the allow_mult property" do
      @bucket.allow_mult.should be_false
    end

    it "should set the allow_mult property" do
      @bucket.should_receive(:props=).with(hash_including('allow_mult' => true))
      @bucket.allow_mult = true
    end
  end

  describe "get/set the N value" do
    before :each do
      do_load
    end

    it "should extract the N value" do
      @bucket.n_value.should == 3
    end

    it "should set the N value" do
      @bucket.should_receive(:props=).with(hash_including('n_val' => 1))
      @bucket.n_value = 1
    end
  end

  [:r, :w, :dw, :rw].each do |q|
    describe "get/set the default #{q} quorum" do
      before :each do
        do_load
      end

      it "should extract the default #{q} quorum" do
        @bucket.send(q).should == "quorum"
      end

      it "should set the #{q} quorum" do
        @bucket.should_receive(:props=).with(hash_including("#{q}" => 1))
        @bucket.send("#{q}=",1)
      end
    end
  end


  describe "checking whether a key exists" do
    it "should return true if the object does exist" do
      @client.http.should_receive(:head).and_return(:code => 200)
      @bucket.exists?("foo").should be_true
    end

    it "should return false if the object doesn't exist" do
      @client.http.should_receive(:head).and_return(:code => 404)
      @bucket.exists?("foo").should be_false
    end
  end

  it "should delete a key from within the bucket" do
    @client.http.should_receive(:delete).with([204,404], @client.prefix, @bucket.name, 'bar',{},{}).and_return(:code => 204)
    @bucket.delete('bar')
  end
end
