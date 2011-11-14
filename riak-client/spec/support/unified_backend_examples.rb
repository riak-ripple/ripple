
shared_examples_for "Unified backend API" do
  # ping
  it "should ping the server" do
    @backend.ping.should be_true
  end

  # fetch_object
  context "fetching an object" do
    before do
      @robject = Riak::RObject.new(@client.bucket("test"), "fetch")
      @robject.indexes['test_bin'] << 'pass'
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
        robj = @backend.fetch_object("test", "fetch", :r => q)
        robj.should be_kind_of(Riak::RObject)
        robj.data.should == { "test" => "pass" }
      end

      it "should accept a PR value of #{q.inspect} for the request" do
        robj = @backend.fetch_object("test", "fetch", :pr => q)
        robj.should be_kind_of(Riak::RObject)
        robj.data.should == { "test" => "pass" }
      end
    end

    it "should marshal indexes properly" do
      # This really tests both storing and fetching indexes, given the setup
      robj = @backend.fetch_object('test', 'fetch')
      robj.indexes['test_bin'].should be
      robj.indexes['test_bin'].should include('pass')
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
      @backend.store_object(@robject2, :returnbody => true)
    end

    it "should modify the object with the reloaded data" do
      @backend.reload_object(@robject)
    end

    [1,2,3,:one,:quorum,:all,:default].each do |q|
      it "should accept a valid R value of #{q.inspect} for the request" do
        @backend.reload_object(@robject, :r => q)
      end

      it "should accept a valid PR value of #{q.inspect} for the request" do
        @backend.reload_object(@robject, :pr => q)
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
      @backend.store_object(@robject, :returnbody => true)
      @robject.vclock.should be_present
    end

    [1,2,3,:one,:quorum,:all,:default].each do |q|
      it "should accept a W value of #{q.inspect} for the request" do
        @backend.store_object(@robject, :returnbody => false, :w => q)
        @client.bucket("test").exists?("store").should be_true
      end

      it "should accept a DW value of #{q.inspect} for the request" do
        @backend.store_object(@robject, :returnbody => false, :w => :all, :dw => q)
      end

      it "should accept a PW value of #{q.inspect} for the request" do
        @backend.store_object(@robject, :returnbody => false, :pw => q)
      end
    end

    after do
      expect { @backend.fetch_object("test", "store") }.should_not raise_error(Riak::FailedRequest)
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
        @backend.delete_object("test", "delete", :rw => q)
      end
    end

    it "should accept a vclock value for the request" do
      @backend.delete_object("test", "delete", :vclock => @obj.vclock)
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
      it "should handle a large number of keys" do
        obj = Riak::RObject.new(@client.bucket("test"))
        obj.content_type = "application/json"
        obj.data = [1]
        750.times do |i|
          obj.key = i.to_s
          obj.store(:w => 1, :dw => 0, :returnbody => false)
        end
        @backend.list_keys("test") do |keys|
          keys.should be_all {|k| k == 'keys' || (0..749).include?(k.to_i) }
        end
      end

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
              @client.get_object("test", key)
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
                @client.get_object("test", v['value'])
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
end
