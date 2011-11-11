require 'spec_helper'
require 'riak/cache_store'

describe Riak::CacheStore do
  before do
    @web_port = $test_server.http_port
    @cache = ActiveSupport::Cache.lookup_store(:riak_store, :http_port => @web_port)
  end

  describe "Riak integration" do
    it "should have a client" do
      @cache.should respond_to(:client)
      @cache.client.should be_kind_of(Riak::Client)
    end

    it "should have a bucket to store entries in" do
      @cache.bucket.should be_kind_of(Riak::Bucket)
    end

    it "should configure the client according to the initialized options" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :http_port => 10000)
      @cache.client.nodes.all? { |n| n.http_port == 10000 }.should == true
    end

    it "should choose the bucket according to the initializer option" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :bucket => "foobar", :http_port => @web_port)
      @cache.bucket.name.should == "foobar"
    end

    it "should set the N value to 2 by default" do
      @cache.bucket.n_value.should == 2
    end

    it "should set the N value to the specified value" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :n_value => 1, :http_port => @web_port)
      @cache.bucket.n_value.should == 1
    end

    it "should set the bucket R value to 1 by default" do
      @cache.bucket.r.should == 1
    end

    it "should set the bucket R default to the specified value" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :r => "quorum", :http_port => @web_port)
      @cache.bucket.r.should == "quorum"
    end

    it "should set the bucket W value to 1 by default" do
      @cache.bucket.w.should == 1
    end

    it "should set the bucket W default to the specified value" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :w => "all", :http_port => @web_port)
      @cache.bucket.w.should == "all"
    end

    it "should set the bucket DW value to 0 by default" do
      @cache.bucket.dw.should == 0
    end

    it "should set the bucket DW default to the specified value" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :dw => "quorum", :http_port => @web_port)
      @cache.bucket.dw.should == "quorum"
    end

    it "should set the bucket RW value to quorum by default" do
      @cache.bucket.rw.should == "quorum"
    end

    it "should set the bucket RW default to the specified value" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :rw => "all", :http_port => @web_port)
      @cache.bucket.rw.should == "all"
    end
  end


  it "should read and write strings" do
    @cache.write('foo', 'bar')
    @cache.read('foo').should == 'bar'
  end

  it "should read and write hashes" do
    @cache.write('foo', {:a => "b"})
    @cache.read('foo').should == {:a => "b"}
  end

  it "should read and write integers" do
    @cache.write('foo', 1)
    @cache.read('foo').should == 1
  end

  it "should read and write nil" do
    @cache.write('foo', nil)
    @cache.read('foo').should be_nil
  end

  it "should return the stored value when fetching on hit" do
    @cache.write('foo', 'bar')
    @cache.fetch('foo'){'baz'}.should == 'bar'
  end

  it "should return the default value when fetching on miss" do
    @cache.fetch('foo'){ 'baz' }.should == 'baz'
  end

  it "should return the default value when forcing a miss" do
    @cache.fetch('foo', :force => true){'bar'}.should == 'bar'
  end

  it "should detect if a value exists in the cache" do
    @cache.write('foo', 'bar')
    @cache.exist?('foo').should be_true
  end

  it "should delete matching keys from the cache" do
    @cache.write('foo', 'bar')
    @cache.write('green', 'thumb')
    @cache.delete_matched(/foo/)
    @cache.read('foo').should be_nil
    @cache.read('green').should == 'thumb'
  end

  it "should delete a single key from the cache" do
    @cache.write('foo', 'bar')
    @cache.read('foo').should == 'bar'
    @cache.delete('foo')
    @cache.read('foo').should be_nil
  end
end
