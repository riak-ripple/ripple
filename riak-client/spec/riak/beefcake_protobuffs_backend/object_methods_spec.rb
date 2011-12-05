require 'spec_helper'
require 'riak/client/beefcake/object_methods'
require 'riak/client/beefcake/messages'

describe Riak::Client::BeefcakeProtobuffsBackend::ObjectMethods do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::BeefcakeProtobuffsBackend.new(@client, @client.node)
    @bucket = Riak::Bucket.new(@client, "bucket")
    @object = Riak::RObject.new(@bucket, "bar")
  end

  describe "loading object data from the response" do
    it "should load the key" do
      content = stub(:value => '', :vtag => nil, :content_type => nil, :links => nil, :usermeta => nil, :last_mod => nil, :indexes => nil)
      pbuf = stub(:vclock => nil, :content => [content], :value => nil, :key => 'akey')
      o = @backend.load_object(pbuf, @object)
      o.should == @object
      o.key.should == pbuf.key
    end
  end

end
