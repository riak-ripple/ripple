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
require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Riak::CacheStore do
  before do
    @cache = ActiveSupport::Cache.lookup_store(:riak_store)
    @cleanup = true
  end

  after do
    @cache.bucket.keys(:force => true).each do |k|
      @cache.bucket.delete(k, :rw => 1) unless k.blank?
    end if @cleanup
  end

  describe "Riak integration" do
    before do
      @cleanup = false
    end

    it "should have a client" do
      @cache.should respond_to(:client)
      @cache.client.should be_kind_of(Riak::Client)
    end

    it "should have a bucket to store entries in" do
      @cache.bucket.should be_kind_of(Riak::Bucket)
    end

    it "should configure the client according to the initialized options" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :port => 10000)
      @cache.client.port.should == 10000
    end

    it "should choose the bucket according to the initializer option" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :bucket => "foobar")
      @cache.bucket.name.should == "foobar"
    end

    it "should set the N value to 2 by default" do
      @cache.bucket.n_value.should == 2
    end

    it "should set the N value to the specified value" do
      @cache = ActiveSupport::Cache.lookup_store(:riak_store, :n_value => 1)
      @cache.bucket.n_value.should == 1
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
    @cache.fetch('foo'){'baz'}.should == 'baz'
  end

  it "should return the default value when forcing a miss" do
    @cache.fetch('foo', :force => true){'bar'}.should == 'bar'
  end

  it "should increment an integer value in the cache" do
    @cache.write('foo', 1, :raw => true)
    @cache.read('foo', :raw => true).to_i.should == 1
    @cache.increment('foo')
    @cache.read('foo', :raw => true).to_i.should == 2
  end

  it "should decrement an integer value in the cache" do
    @cache.write('foo', 1, :raw => true)
    @cache.read('foo', :raw => true).to_i.should == 1
    @cache.decrement('foo')
    @cache.read('foo', :raw => true).to_i.should == 0
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
