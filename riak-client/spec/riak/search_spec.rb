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
require File.expand_path('../../spec_helper', __FILE__)

describe "Search mixins" do
  before :all do
    require 'riak/search'
  end

  describe Riak::Client do
    before :each do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @client.stub!(:http).and_return(@http)
    end
    describe "searching" do
      it "should exclude the index from the URL when not specified" do
        @http.should_receive(:get).with(200, "/solr", "select", hash_including("q" => "foo"), {}).and_return({:code => 200, :headers => {"content-type"=>["application/json"]}, :body => "{}"})
        @client.search("foo")
      end

      it "should include extra options in the query string" do
        @http.should_receive(:get).with(200, "/solr", "select", hash_including('rows' => 30), {}).and_return({:code => 200, :headers => {"content-type"=>["application/json"]}, :body => "{}"})
        @client.search("foo", 'rows' => 30)
      end

      it "should include the index in the URL when specified" do
        @http.should_receive(:get).with(200, "/solr", "search", "select", hash_including("q" => "foo"), {}).and_return({:code => 200, :headers => {"content-type"=>["application/json"]}, :body => "{}"})
        @client.search("search", "foo")
      end

      it "should vivify JSON responses" do
        @http.should_receive(:get).and_return({:code => 200, :headers => {"content-type"=>["application/json"]}, :body => '{"response":{"docs":["foo"]}}'})
        @client.search("foo").should == {"response" => {"docs" => ["foo"]}}
      end

      it "should return non-JSON responses raw" do
        @http.should_receive(:get).and_return({:code => 200, :headers => {"content-type"=>["text/plain"]}, :body => '{"response":{"docs":["foo"]}}'})
        @client.search("foo").should == '{"response":{"docs":["foo"]}}'
      end
    end
    describe "indexing documents" do
      it "should exclude the index from the URL when not specified" do
        @http.should_receive(:post).with(200, "/solr", "update", anything, anything).and_return({:code => 200, :headers => {'content-type' => ['text/html']}, :body => ""})
        @client.index({:id => 1, :field => "value"})
      end

      it "should include the index in the URL when specified" do
        @http.should_receive(:post).with(200, "/solr", "foo", "update", anything, anything).and_return({:code => 200, :headers => {'content-type' => ['text/html']}, :body => ""})
        @client.index("foo", {:id => 1, :field => "value"})
      end

      it "should raise an error when documents do not contain an id" do
        @http.stub!(:post).and_return(true)
        lambda { @client.index({:field => "value"}) }.should raise_error(ArgumentError)
        lambda { @client.index({:id => 1, :field => "value"}) }.should_not raise_error(ArgumentError)
      end

      it "should build a Solr <add> request" do
        expect_update_body('<add><doc><field name="id">1</field><field name="field">value</field></doc></add>')
        @client.index({:id => 1, :field => "value"})
      end

      it "should include multiple documents in the <add> request" do
        expect_update_body('<add><doc><field name="id">1</field><field name="field">value</field></doc><doc><field name="id">2</field><field name="foo">bar</field></doc></add>')
        @client.index({:id => 1, :field => "value"}, {:id => 2, :foo => "bar"})
      end
    end
    describe "removing documents" do
      it "should exclude the index from the URL when not specified" do
        @http.should_receive(:post).with(200, "/solr","update", anything, anything).and_return({:code => 200, :headers => {'content-type' => ['text/html']}, :body => ""})
        @client.remove({:id => 1})
      end

      it "should include the index in the URL when specified" do
        @http.should_receive(:post).with(200, "/solr", "foo", "update", anything, anything).and_return({:code => 200, :headers => {'content-type' => ['text/html']}, :body => ""})
        @client.remove("foo", {:id => 1})
      end

      it "should raise an error when document specifications don't include an id or query" do
        @http.stub!(:post).and_return({:code => 200})
        lambda { @client.remove({:foo => "bar"}) }.should raise_error(ArgumentError)
        lambda { @client.remove({:id => 1}) }.should_not raise_error
      end

      it "should build a Solr <delete> request" do
        expect_update_body('<delete><id>1</id></delete>')
        @client.remove(:id => 1)
        expect_update_body('<delete><query>title:old</query></delete>')
        @client.remove(:query => "title:old")
      end

      it "should include multiple specs in the <delete> request" do
        expect_update_body('<delete><id>1</id><query>title:old</query></delete>')
        @client.remove({:id => 1}, {:query => "title:old"})
      end
    end

    def expect_update_body(body, index=nil)
      args = [200, "/solr", index, "update", body, {"Content-Type" => "text/xml"}].compact
      @http.should_receive(:post).with(*args).and_return({:code => 200, :headers => {'content-type' => ['text/html']}, :body => ""})
    end
  end

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
    alias :load_without_index_hook :do_load

    def load_with_index_hook
      do_load(:body => '{"props":{"precommit":[{"mod":"riak_search_kv_hook","fun":"precommit"}]}}')
    end

    it "should detect whether the indexing hook is installed" do
      load_without_index_hook
      @bucket.props['precommit'].should be_empty
      @bucket.is_indexed?.should be_false

      load_with_index_hook
      @bucket.props['precommit'].should_not be_empty
      @bucket.is_indexed?.should be_true
    end

    describe "enabling indexing" do
      it "should add the index hook when not present" do
        load_without_index_hook
        @bucket.should_receive(:props=).with({"precommit" => [Riak::Bucket::SEARCH_PRECOMMIT_HOOK]})
        @bucket.enable_index!
      end

      it "should not modify the precommit when the hook is present" do
        load_with_index_hook
        @bucket.should_not_receive(:props=)
        @bucket.enable_index!
      end
    end

    describe "disabling indexing" do
      it "should remove the index hook when present" do
        load_with_index_hook
        @bucket.should_receive(:props=).with({"precommit" => []})
        @bucket.disable_index!
      end

      it "should not modify the precommit when the hook is missing" do
        load_without_index_hook
        @bucket.should_not_receive(:props=)
        @bucket.disable_index!
      end
    end
  end

  describe Riak::MapReduce do
    before :each do
      @client = Riak::Client.new
      @mr = Riak::MapReduce.new(@client)
    end

    describe "using a search query as inputs" do
      it "should accept a bucket name and query" do
        @mr.search("foo", "bar OR baz")
        @mr.inputs.should == {:module => "riak_search", :function => "mapred_search", :arg => ["foo", "bar OR baz"]}
      end

      it "should accept a Riak::Bucket and query" do
        @mr.search(Riak::Bucket.new(@client, "foo"), "bar OR baz")
        @mr.inputs.should == {:module => "riak_search", :function => "mapred_search", :arg => ["foo", "bar OR baz"]}
      end

      it "should emit the Erlang function and arguments" do
        @mr.search("foo", "bar OR baz")
        @mr.to_json.should include('"inputs":{')
        @mr.to_json.should include('"module":"riak_search"')
        @mr.to_json.should include('"function":"mapred_search"')
        @mr.to_json.should include('"arg":["foo","bar OR baz"]')
      end
    end
  end
end
