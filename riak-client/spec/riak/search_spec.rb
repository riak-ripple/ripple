require 'spec_helper'

describe "Search features" do
  describe Riak::Client do
    before :each do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @client.stub!(:http).and_yield(@http)
    end

    describe "searching" do
      it "should search the default index" do
        @http.should_receive(:search).with(nil, "foo", {}).and_return({})
        @client.search("foo")
      end

      it "should search the default index with additional options" do
        @http.should_receive(:search).with(nil, 'foo', 'rows' => 30).and_return({})
        @client.search("foo", 'rows' => 30)
      end

      it "should search the specified index" do
        @http.should_receive(:search).with('search', 'foo', {}).and_return({})
        @client.search("search", "foo")
      end
    end

    describe "indexing documents" do
      it "should update the default index" do
        doc = {'field' => "value", 'id' => 1}
        if doc.to_a.first.first == 'field'
          expect_update_body('<add><doc><field name="field">value</field><field name="id">1</field></doc></add>')
        else # 1.8.7, I hate you.
          expect_update_body('<add><doc><field name="id">1</field><field name="field">value</field></doc></add>')
        end
        @client.index(doc)
      end

      it "should update the specified index" do
        doc = {'field' => "value", 'id' => 1}
        if doc.to_a.first.first == 'field'
          expect_update_body('<add><doc><field name="field">value</field><field name="id">1</field></doc></add>', 'foo')
        else # 1.8.7, I hate you.
          expect_update_body('<add><doc><field name="id">1</field><field name="field">value</field></doc></add>', 'foo')
        end
        @client.index("foo", doc)
      end

      it "should raise an error when documents do not contain an id" do
        @http.stub!(:update_search_index).and_return(true)
        lambda { @client.index({:field => "value"}) }.should raise_error(ArgumentError)
        lambda { @client.index({:id => 1, :field => "value"}) }.should_not raise_error(ArgumentError)
      end

      it "should include multiple documents in the <add> request" do
        docs = {'field' => "value", 'id' => 1}, {'foo' => "bar", 'id' => 2}
        if docs.first.to_a.first.first == 'field'
          expect_update_body('<add><doc><field name="field">value</field><field name="id">1</field></doc><doc><field name="foo">bar</field><field name="id">2</field></doc></add>')
        else # 1.8.7, I hate you
          expect_update_body('<add><doc><field name="id">1</field><field name="field">value</field></doc><doc><field name="id">2</field><field name="foo">bar</field></doc></add>')
        end
        @client.index(*docs)
      end
    end

    describe "removing documents" do
      it "should remove documents from the default index" do
        expect_update_body('<delete><id>1</id></delete>')
        @client.remove({:id => 1})
      end

      it "should remove documents from the specified index" do
        expect_update_body('<delete><id>1</id></delete>', 'foo')
        @client.remove("foo", {:id => 1})
      end

      it "should raise an error when document specifications don't include an id or query" do
        @http.stub!(:update_search_index).and_return({:code => 200})
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
      @http.should_receive(:update_search_index).with(index, body)
    end
  end

  describe Riak::Bucket do
    before :each do
      @client = Riak::Client.new
      @bucket = Riak::Bucket.new(@client, "foo")
    end

    def load_without_index_hook
      @bucket.instance_variable_set(:@props, {"precommit" => [], "search" => false})
    end

    def load_with_index_hook
      @bucket.instance_variable_set(:@props, {"precommit" => [{"mod" => "riak_search_kv_hook", "fun" => "precommit"}], "search" => true})
    end

    it "should detect whether the indexing hook is installed" do
      load_without_index_hook
      @bucket.is_indexed?.should be_false

      load_with_index_hook
      @bucket.is_indexed?.should be_true
    end

    describe "enabling indexing" do
      it "should add the index hook when not present" do
        load_without_index_hook
        @bucket.should_receive(:props=).with({"precommit" => [Riak::Bucket::SEARCH_PRECOMMIT_HOOK], "search" => true})
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
        @bucket.should_receive(:props=).with({"precommit" => [], "search" => false})
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
