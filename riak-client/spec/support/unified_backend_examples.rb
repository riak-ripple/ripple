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

shared_examples_for "Unified backend API" do
  # ping
  it "should ping the server" do
    @backend.ping.should be_true
  end

  # fetch_object
  context "fetching an object" do
    before do
      @robject = Riak::RObject.new(@client.bucket("test"), "fetch")
      @robject.content_type = "application/json"
      @robject.data = { "test" => "pass" }
      @backend.store_object(@robject)
    end

    it "should find a stored object" do
      robj = @backend.fetch_object("test", "fetch")
      robj.should be_kind_of(Riak::RObject)
      robj.data.should == { "test" => "pass" }
    end

    it "should raise an error when the object is not found" do
      begin
        @backend.fetch_object("test", "notfound")
      rescue Riak::FailedRequest => exception
        @exception = exception
      end
      @exception.should be_kind_of(Riak::FailedRequest)
      @exception.should be_not_found
    end

    [1,2,3,:one,:quorum,:all,:default].each do |q|
      it "should accept a R value of #{q.inspect} for the request" do
        robj = @backend.fetch_object("test", "fetch", q)
        robj.should be_kind_of(Riak::RObject)
        robj.data.should == { "test" => "pass" }
      end
    end
  end

  # reload_object
  context "reloading an existing object" do
    before do
      @robject = Riak::RObject.new(@client.bucket('test'), 'reload')
      @robject.content_type = "application/json"
      @robject.data = {"test" => "pass"}
      @backend.store_object(@robject)
      @robject2 = @backend.fetch_object("test", "reload")
      @robject2.data["test"] = "second"
      @backend.store_object(@robject2, true)
    end

    it "should modify the object with the reloaded data" do
      @backend.reload_object(@robject)
    end

    [1,2,3,:one,:quorum,:all,:default].each do |q|
      it "should accept a valid R value of #{q.inspect} for the request" do
        @backend.reload_object(@robject, q)
      end
    end

    after do
      @robject.vclock.should == @robject2.vclock
      @robject.data['test'].should == "second"
    end
  end

  # store_object
  context "storing an object" do
    before do
      @robject = Riak::RObject.new(@client.bucket('test'), 'store')
      @robject.content_type = "application/json"
      @robject.data = {"test" => "pass"}
    end

    it "should save the object" do
      @backend.store_object(@robject)
    end

    it "should modify the object with the returned data if returnbody" do
      @backend.store_object(@robject, true)
      @robject.vclock.should be_present
    end

    [1,2,3,:one,:quorum,:all,:default].each do |q|
      it "should accept a W value of #{q.inspect} for the request" do
        @backend.store_object(@robject, false, q)
        @client.bucket("test").exists?("store").should be_true
      end

      it "should accept a DW value of #{q.inspect} for the request" do
        @backend.store_object(@robject, false, nil, q)
      end
    end

    after do
      @client.bucket("test").exists?("store").should be_true
    end
  end

  # delete_object
  context "deleting an object" do
    before do
      @obj = Riak::RObject.new(@client.bucket("test"), "delete")
      @obj.content_type = "application/json"
      @obj.data = [1]
      @backend.store_object(@obj)
    end

    it "should remove the object" do
      @backend.delete_object("test", "delete")
      @obj.bucket.exists?("delete").should be_false
    end

    [1,2,3,:one,:quorum,:all,:default].each do |q|
      it "should accept an RW value of #{q.inspect} for the request" do
        @backend.delete_object("test", "delete", q)
      end
    end

    after do
      @obj.bucket.exists?("delete").should be_false
    end
  end

  # get_bucket_props
  context "fetching bucket properties" do
    it "should fetch a hash of bucket properties" do
      props = @backend.get_bucket_props("test")
      props.should be_kind_of(Hash)
      props.should include("n_val")
    end
  end

  # set_bucket_props
  context "setting bucket properties" do
    it "should store properties for the bucket" do
      @backend.set_bucket_props("test", {"n_val" => 3})
      @backend.get_bucket_props("test")["n_val"].should == 3
    end
  end

  # list_keys
  context "listing keys in a bucket" do
    before do
      obj = Riak::RObject.new(@client.bucket("test"), "keys")
      obj.content_type = "application/json"
      obj.data = [1]
      @backend.store_object(obj)
    end

    it "should fetch an array of string keys" do
      @backend.list_keys("test").should == ["keys"]
    end

    context "streaming through a block" do
      it "should pass an array of keys to the block" do
        @backend.list_keys("test") do |keys|
          keys.should == ["keys"] unless keys.empty?
        end
      end

      it "should allow requests issued inside the block to execute" do
        errors = []
        @backend.list_keys("test") do |keys|
          keys.each do |key|
            begin
              @backend.fetch_object("test", key)
            rescue => e
              errors << e
            end
          end
        end
        errors.should be_empty
      end
    end
  end

  # list_buckets
  context "listing buckets" do
    before do
      obj = Riak::RObject.new(@client.bucket("test"), "buckets")
      obj.content_type = "application/json"
      obj.data = [1]
      @backend.store_object(obj)
    end

    it "should fetch a list of string bucket names" do
      list = @backend.list_buckets
      list.should be_kind_of(Array)
      list.should include("test")
    end
  end

  # mapred
  context "performing MapReduce" do
    before do
      obj = Riak::RObject.new(@client.bucket("test"), "1")
      obj.content_type = "application/json"
      obj.data = {"value" => "1" }
      @backend.store_object(obj)
      @mapred = Riak::MapReduce.new(@client).add("test").map("Riak.mapValuesJson", :keep => true)
    end

    it "should perform a simple MapReduce request" do
      @backend.mapred(@mapred).should == [{"value" => "1"}]
    end

    context "streaming results through a block" do
      it "should pass phase number and result to the block" do
        @backend.mapred(@mapred) do |phase, result|
          unless result.empty?
            phase.should == 0
            result.should == [{"value" => "1"}]
          end
        end
      end

      it "should allow requests issued inside the block to execute" do
        errors = []
        @backend.mapred(@mapred) do |phase, result|
          unless result.empty?
            result.each do |v|
              begin
                @backend.fetch_object("test", v['value'])
              rescue => e
                errors << e
              end
            end
          end
        end
        errors.should be_empty
      end
    end
  end

  after do
    $test_server.recycle if $test_server.started?
  end
end
