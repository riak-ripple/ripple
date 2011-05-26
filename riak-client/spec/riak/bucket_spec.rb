require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::Bucket do
  before :each do
    @client = Riak::Client.new
    @backend = mock("Backend")
    @client.stub!(:backend).and_return(@backend)
    @bucket = Riak::Bucket.new(@client, "foo")
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

  describe "accessing keys" do
    it "should list the keys" do
      @backend.should_receive(:list_keys).with(@bucket).and_return(["bar"])
      @bucket.keys.should == ["bar"]
    end

    it "should allow streaming keys through block" do
      @backend.should_receive(:list_keys).with(@bucket).and_yield([]).and_yield(["bar"]).and_yield(["baz"])
      all_keys = []
      @bucket.keys do |list|
        all_keys.concat(list)
      end
      all_keys.should == ["bar", "baz"]
    end

    it "should not cache the list of keys" do
      @backend.should_receive(:list_keys).with(@bucket).twice.and_return(["bar"])
      2.times { @bucket.keys.should == ['bar'] }
    end

    it "should warn about the expense of list-keys when warnings are not disabled" do
      Riak.disable_list_keys_warnings = false
      @backend.stub!(:list_keys).and_return(%w{test test2})
      @bucket.should_receive(:warn)
      @bucket.keys
      Riak.disable_list_keys_warnings = true
    end
  end

  describe "setting the bucket properties" do
    it "should prefetch the properties when they are not present" do
      @backend.stub!(:set_bucket_props)
      @backend.should_receive(:get_bucket_props).with(@bucket).and_return({"name" => "foo"})
      @bucket.props = {"precommit" => []}
    end

    it "should set the new properties on the bucket" do
      @bucket.instance_variable_set(:@props, {}) # Pretend they are there
      @backend.should_receive(:set_bucket_props).with(@bucket, { :name => "foo" })
      @bucket.props = { :name => "foo" }
    end

    it "should raise an error if an invalid type is given" do
      lambda { @bucket.props = "blah" }.should raise_error(ArgumentError)
    end
  end

  describe "fetching the bucket properties" do
    it "should fetch properties on first access" do
      @bucket.instance_variable_get(:@props).should be_nil
      @backend.should_receive(:get_bucket_props).with(@bucket).and_return({"name" => "foo"})
      @bucket.props.should == {"name" => "foo"}
    end

    it "should memoize fetched properties" do
      @backend.should_receive(:get_bucket_props).once.with(@bucket).and_return({"name" => "foo"})
      @bucket.props.should == {"name" => "foo"}
      @bucket.props.should == {"name" => "foo"}
    end
  end

  describe "fetching an object" do
    it "should fetch the object via the backend" do
      @backend.should_receive(:fetch_object).with(@bucket, "db", nil).and_return(nil)
      @bucket.get("db")
    end

    it "should use the specified R quroum" do
      @backend.should_receive(:fetch_object).with(@bucket, "db", 2).and_return(nil)
      @bucket.get("db", :r => 2)
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
    it "should return the existing object if present" do
      @object = mock("RObject")
      @backend.should_receive(:fetch_object).with(@bucket,"db", nil).and_return(@object)
      @bucket.get_or_new('db').should == @object
    end

    it "should create a new blank object if the key does not exist" do
      @backend.should_receive(:fetch_object).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "File not found"))
      obj = @bucket.get_or_new('db')
      obj.key.should == 'db'
      obj.data.should be_blank
    end

    it "should bubble up non-ok non-missing errors" do
      @backend.should_receive(:fetch_object).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 500, {}, "File not found"))
      lambda { @bucket.get_or_new('db') }.should raise_error(Riak::HTTPFailedRequest)
    end

    it "should pass along the given R quorum parameter" do
      @object = mock("RObject")
      @backend.should_receive(:fetch_object).with(@bucket,"db", "all").and_return(@object)
      @bucket.get_or_new('db', :r => "all").should == @object
    end
  end

  describe "get/set allow_mult property" do
    before :each do
      @backend.stub!(:get_bucket_props).and_return({"allow_mult" => false})
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
      @backend.stub!(:get_bucket_props).and_return({"n_val" => 3})
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
        @backend.stub!(:get_bucket_props).and_return({"r" => "quorum", "w" => "quorum", "dw" => "quorum", "rw" => "quorum"})
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
      @backend.should_receive(:fetch_object).and_return(mock)
      @bucket.exists?("foo").should be_true
    end

    it "should return false if the object doesn't exist" do
      @backend.should_receive(:fetch_object).and_raise(Riak::HTTPFailedRequest.new(:get, [200,300], 404, {}, "not found"))
      @bucket.exists?("foo").should be_false
    end
  end

  describe "deleting an object" do
    it "should delete a key from within the bucket" do
      @backend.should_receive(:delete_object).with(@bucket, "bar", nil)
      @bucket.delete('bar')
    end

    it "should use the specified RW quorum" do
      @backend.should_receive(:delete_object).with(@bucket, "bar", "all")
      @bucket.delete('bar', :rw => "all")
    end
  end
end
