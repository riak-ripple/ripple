require 'spec_helper'

describe Riak::Node do
  before :each do
    @client = Riak::Client.new
    @node = Riak::Client::Node.new @client
  end

  describe 'when initializing' do
    it 'should default to the local interface on port 8098/8087' do
      node = Riak::Client::Node.new @client
      node.host.should == '127.0.0.1'
      node.http_port.should == 8098
      node.pb_port.should == 8087
    end

    it 'should accept a host' do
      node = Riak::Client::Node.new(@client, :host => 'riak.basho.com')
      node.host.should == "riak.basho.com"
    end

    it 'should accept an HTTP port' do
      node = Riak::Client::Node.new(@client, :http_port => 9000)
      node.http_port.should == 9000
    end

    it 'should accept a Protobuffs port' do
      node = Riak::Client::Node.new @client, :pb_port => 9000
      node.pb_port.should == 9000
    end

    it 'should accept basic_auth' do
      node = Riak::Client::Node.new @client, :basic_auth => 'user:pass'
      node.basic_auth.should == "user:pass"
    end

    it 'should accept a path prefix' do
      node = Riak::Client::Node.new @client, :prefix => "/jiak/"
      node.http_paths[:prefix].should == "/jiak/"
    end

    it 'default prefix should be /riak/' do
      @node.http_paths[:prefix].should == "/riak/"
    end

    it 'should accept a mapreduce path' do
      node = Riak::Client::Node.new @client, :mapred => "/mr"
      node.http_paths[:mapred].should == "/mr"
    end

    it "default mapreduce path should be /mapred" do
      @node.http_paths[:mapred].should == "/mapred"
    end

    it 'should accept a solr path' do
      node = Riak::Client::Node.new @client, :solr => "/mr"
      node.http_paths[:solr].should == "/mr"
    end

    it "default solr path should be /solr" do
      @node.http_paths[:solr].should == "/solr"
    end

    it 'should accept a luwak path' do
      node = Riak::Client::Node.new @client, :luwak => "/mr"
      node.http_paths[:luwak].should == "/mr"
    end

    it "default luwak path should be /luwak" do
      @node.http_paths[:luwak].should == "/luwak"
    end
  end

  describe "setting http auth" do
    it "should allow setting basic_auth" do
      @node.should respond_to(:basic_auth=)
      @node.basic_auth = "user:pass"
      @node.basic_auth.should == "user:pass"
      @node.basic_auth = nil
      @node.basic_auth.should == nil
    end

    it "should require that basic auth splits into two even parts" do
      lambda { @node.basic_auth ="user" }.should raise_error(ArgumentError, "basic auth must be set using 'user:pass'")
    end
  end

  describe 'ssl' do
    before :each do
      @client = Riak::Client.new
      @node = Riak::Client::Node.new @client
    end

    it 'should not allow reading ssl options via ssl' do
      @node.should_not respond_to(:ssl)
    end

    it 'should allow setting ssl to true' do
      @node.ssl = true
      @node.ssl_options[:verify_mode].should eq('none')
    end

    it "should should clear ssl options when setting ssl to false" do
      @node.ssl = true
      @node.ssl_options.should_not be_nil
      @node.ssl = false
      @node.ssl_options.should be_nil
    end

    it "should allow setting the verify_mode to none" do
      @node.ssl = {:verify_mode => "none"}
      @node.ssl_options[:verify_mode].should eq("none")
    end

    it "should allow setting the verify_mode to peer" do
      @node.ssl = {:verify_mode => "peer"}
      @node.ssl_options[:verify_mode].should eq("peer")
    end

    it "should not allow setting the verify_mode to anything else" do
      lambda {@node.ssl = {:verify_mode => :your_mom}}.should raise_error(ArgumentError)
    end

    it "should default verify_mode to none" do
      @node.ssl = true
      @node.ssl_options[:verify_mode].should eq("none")
    end

    it "should let the backend know if ssl is enabled" do
      @node.should_not be_ssl_enabled
      @node.ssl = true
      @node.should be_ssl_enabled
    end

    it "should allow setting the pem" do
      @node.ssl = {:pem => 'i-am-a-pem'}
      @node.ssl_options[:pem].should eq('i-am-a-pem')
    end

    it "should set them pem from the contents of pem_file" do
      filepath = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test.pem'))
      @node.ssl = {:pem_file => filepath}
      @node.ssl_options[:pem].should eq("i-am-a-pem\n")
    end

    it "should allow setting the pem_password" do
      @node.ssl = {:pem_password => 'pem-pass'}
      @node.ssl_options[:pem_password].should eq('pem-pass')
    end

    it "should allow setting the ca_file" do
      @node.ssl = {:ca_file => '/path/to/ca.crt'}
      @node.ssl_options[:ca_file].should eq('/path/to/ca.crt')
    end

    it "should allow setting the ca_path" do
      @node.ssl = {:ca_path => '/path/to/certs/'}
      @node.ssl_options[:ca_path].should eq('/path/to/certs/')
    end

    %w[pem ca_file ca_path].each do |option|
      it "should default the verify_mode to peer when setting the #{option}" do
        @node.ssl = {option.to_sym => 'test-data'}
        @node.ssl_options[:verify_mode].should eq("peer")
      end

      it "should allow setting the verify mode when setting the #{option}" do
        @node.ssl = {option.to_sym => 'test-data', :verify_mode => "none"}
        @node.ssl_options[:verify_mode].should eq("none")
      end
    end
  end
end
