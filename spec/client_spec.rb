require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Client do
  describe "when initializing" do
    it "should require a host and port" do
      lambda { Riak::Client.new(:host => nil, :port => nil) }.should raise_error
    end
    
    it "should default to the local interface on port 8098" do
      client = Riak::Client.new
      client.host.should == "127.0.0.1"
      client.port.should == 8098
    end
    
    it "should accept a client ID" do
      client = Riak::Client.new :client_id => "AAAAAA=="
      client.client_id.should == "AAAAAA=="
    end
    
    it "should turn an integer client ID into a base64-encoded string" do
      client = Riak::Client.new :client_id => 1
      client.client_id.should == "AAAAAQ=="
    end
    
    it "should create a client ID if not specified" do
      Riak::Client.new.client_id.should be_kind_of(String)
    end
    
    it "should accept a path prefix" do
      client = Riak::Client.new(:prefix => "/jiak/")
      client.prefix.should == "/jiak/"
    end
    
    it "should default the prefix to /raw/ if not specified" do
      Riak::Client.new.prefix.should == "/raw/"
    end
  end

  describe "setting a client id" do
    before :each do
      @client = Riak::Client.new
    end
    
    it "should accept a string unmodified" do
      @client.client_id = "foo"
      @client.client_id.should == "foo"
    end

    it "should base64-encode an integer" do
      @client.client_id = 1
      @client.client_id.should == "AAAAAQ=="
    end

    it "should reject an integer equal to the maximum client id" do
      lambda { @client.client_id = Riak::Client::MAX_CLIENT_ID }.should raise_error(ArgumentError)      
    end
    
    it "should reject an integer larger than the maximum client id" do
      lambda { @client.client_id = Riak::Client::MAX_CLIENT_ID + 1 }.should raise_error(ArgumentError)      
    end
  end

  describe "reconfiguring" do
    before :each do
      @client = Riak::Client.new
    end
    
    it "should allow setting the host" do    
      @client.should respond_to(:host=)
      @client.host = "riak.basho.com"
      @client.host.should == "riak.basho.com"
    end

    it "should require the host to be an IP or hostname" do
      [238472384972, "*+=@!"].each do |invalid|
        lambda { @client.host = invalid }.should raise_error(ArgumentError)
      end
      ["127.0.0.1", "10.0.100.5", "localhost", "otherhost.local", "riak.basho.com"].each do |valid|
        lambda { @client.host = valid }.should_not raise_error
      end
    end

    it "should allow setting the port" do
      @client.should respond_to(:port=)
      @client.port = 9000
      @client.port.should == 9000
    end

    it "should require the port to be a valid number" do
      [0,-1,65536,"foo"].each do |invalid|
        lambda { @client.port = invalid }.should raise_error(ArgumentError)
      end
      [1,65535,8098].each do |valid|
        lambda { @client.port = valid }.should_not raise_error
      end
    end
  end
end
