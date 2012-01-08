require 'spec_helper'

describe Riak::Client do
  describe "when initializing" do
    it "should default a single local node" do
      client = Riak::Client.new
      client.nodes.should == [Riak::Client::Node.new(client)]
    end

    it "should accept a protocol" do
      client = Riak::Client.new :protocol => 'https'
      client.protocol.should eq('https')
    end

    it "should accept a host" do
      client = Riak::Client.new :host => "riak.basho.com"
      client.nodes.size.should == 1
      client.nodes.first.host.should == "riak.basho.com"
    end

    it "should accept an HTTP port" do
      client = Riak::Client.new :http_port => 9000
      client.nodes.size.should == 1
      client.nodes.first.http_port.should == 9000
    end

    it "should accept a Protobuffs port" do
      client = Riak::Client.new :pb_port => 9000
      client.nodes.size.should == 1
      client.nodes.first.pb_port.should == 9000
    end

    it "should warn on setting :port" do
      # TODO: make a deprecation utility class/module instead
      client = Riak::Client.allocate
      client.should_receive(:warn).and_return(true)
      client.send :initialize, :port => 9000
    end

    it "should accept basic_auth" do
      client = Riak::Client.new :basic_auth => "user:pass"
      client.nodes.size.should == 1
      client.nodes.first.basic_auth.should eq("user:pass")
    end

    it "should accept a client ID" do
      client = Riak::Client.new :client_id => "AAAAAA=="
      client.client_id.should == "AAAAAA=="
    end

    it "should create a client ID if not specified" do
      Riak::Client.new.client_id.should_not be_nil
    end

    it "should accept a path prefix" do
      client = Riak::Client.new(:prefix => "/jiak/")
      client.nodes.first.http_paths[:prefix].should == "/jiak/"
    end

    it "should accept a mapreduce path" do
      client = Riak::Client.new(:mapred => "/mr")
      client.nodes.first.http_paths[:mapred].should == "/mr"
    end

    it "should accept a luwak path" do
      client = Riak::Client.new(:luwak => "/beans")
      client.nodes.first.http_paths[:luwak].should == "/beans"
    end

    it "should accept a solr path" do
      client = Riak::Client.new(:solr => "/solar")
      client.nodes.first.http_paths[:solr].should == "/solar"
    end
  end

  it "should expose a Stamp object" do
    subject.should respond_to(:stamp)
    subject.stamp.should be_kind_of(Riak::Stamp)
  end

  describe "reconfiguring" do
    before :each do
      @client = Riak::Client.new
    end

    describe "setting the protocol" do
      it "should allow setting the protocol" do
        @client.should respond_to(:protocol=)
        @client.protocol = "https"
        @client.protocol.should eq("https")
      end

      it "should require a valid protocol to be set" do
        lambda { @client.protocol = 'invalid-protocol' }.should(
                                                           raise_error(ArgumentError, /^'invalid-protocol' is not a valid protocol/))
      end
    end

    describe "setting http auth" do
      it "should allow setting basic_auth" do
        @client.should respond_to(:basic_auth=)
        @client.basic_auth = "user:pass"
        @client.nodes.each do |node|
          node.basic_auth.should eq("user:pass")
        end
      end
    end

    describe "setting the client id" do
      it "should accept a string unmodified" do
        @client.client_id = "foo"
        @client.client_id.should == "foo"
      end

      it "should reject an integer equal to the maximum client id" do
        lambda { @client.client_id = Riak::Client::MAX_CLIENT_ID }.should raise_error(ArgumentError)
      end

      it "should reject an integer larger than the maximum client id" do
        lambda { @client.client_id = Riak::Client::MAX_CLIENT_ID + 1 }.should raise_error(ArgumentError)
      end
    end
  end

  describe "choosing an HTTP backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "should choose the selected backend" do
      @client.http_backend = :NetHTTP
      @client.http do |h|
        h.should be_instance_of(Riak::Client::NetHTTPBackend)
      end

      @client = Riak::Client.new
      @client.http_backend = :Excon
      @client.http do |h|
        h.should be_instance_of(Riak::Client::ExconBackend)
      end
    end

    it "should clear the existing HTTP connections when changed" do
      @client.http_pool.should_receive(:clear)
      @client.http_backend = :Excon
    end

    it "should raise an error when the chosen backend is not valid" do
      Riak::Client::NetHTTPBackend.should_receive(:configured?).and_return(false)
      lambda { @client.http { |x| } }.should raise_error
    end
  end

  describe "choosing a Protobuffs backend" do
    before :each do
      @client = Riak::Client.new(:protocol => "pbc")
    end

    it "should choose the selected backend" do
      @client.protobuffs_backend = :Beefcake
      @client.protobuffs do |p|
        p.should be_instance_of(Riak::Client::BeefcakeProtobuffsBackend)
      end
    end

    it "should teardown the existing Protobuffs connections when changed" do
      @client.protobuffs_pool.should_receive(:clear)
      @client.protobuffs_backend = :Beefcake
    end

    it "should raise an error when the chosen backend is not valid" do
      Riak::Client::BeefcakeProtobuffsBackend.should_receive(:configured?).and_return(false)
      lambda { @client.protobuffs { |x| } }.should raise_error
    end
  end

  describe "choosing a unified backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "should use HTTP when the protocol is http or https" do
      %w[http https].each do |p|
        @client.protocol = p
        @client.backend do |b|
          b.should be_kind_of(Riak::Client::HTTPBackend)
        end
      end
    end

    it "should use Protobuffs when the protocol is pbc" do
      @client.protocol = "pbc"
      @client.backend do |b|
        b.should be_kind_of(Riak::Client::ProtobuffsBackend)
      end
    end
  end

  describe "retrieving a bucket" do
    before :each do
      @client = Riak::Client.new
      @backend = mock("Backend")
      @client.stub!(:backend).and_yield(@backend)
    end

    it "should return a bucket object" do
      @client.bucket("foo").should be_kind_of(Riak::Bucket)
    end

    it "should fetch bucket properties if asked" do
      @backend.should_receive(:get_bucket_props) {|b| b.name.should == "foo"; {} }
      @client.bucket("foo", :props => true)
    end

    it "should memoize bucket parameters" do
      @bucket = mock("Bucket")
      Riak::Bucket.should_receive(:new).with(@client, "baz").once.and_return(@bucket)
      @client.bucket("baz").should == @bucket
      @client.bucket("baz").should == @bucket
    end
  end

  describe "listing buckets" do
    before do
      @client = Riak::Client.new
      @backend = mock("Backend")
      @client.stub!(:backend).and_yield(@backend)
    end

    after { Riak.disable_list_keys_warnings = true }

    it "should list buckets" do
      @backend.should_receive(:list_buckets).and_return(%w{test test2})
      buckets = @client.buckets
      buckets.should have(2).items
      buckets.should be_all {|b| b.is_a?(Riak::Bucket) }
      buckets[0].name.should == "test"
      buckets[1].name.should == "test2"
    end

    it "should warn about the expense of list-buckets when warnings are not disabled" do
      Riak.disable_list_keys_warnings = false
      @backend.stub!(:list_buckets).and_return(%w{test test2})
      @client.should_receive(:warn)
      @client.buckets
    end
  end

  describe "Luwak (large-files) support" do
    describe "storing a file" do
      before :each do
        @client = Riak::Client.new
        @http = mock(Riak::Client::HTTPBackend)
        @http.stub!(:node).and_return(@client.node)
        @client.stub!(:http).and_yield(@http)
      end

      it "should store the file via the HTTP interface" do
        @http.should_receive(:store_file).with("text/plain", "Hello, world").and_return("123456789")
        @client.store_file("text/plain", "Hello, world").should == "123456789"
      end
    end

    describe "retrieving a file" do
      before :each do
        @client = Riak::Client.new
        @http = mock(Riak::Client::HTTPBackend)
        @http.stub!(:node).and_return(@client.node)
        @client.stub!(:http).and_yield(@http)
      end

      it "should fetch via HTTP" do
        @http.should_receive(:get_file).with("greeting.txt")
        @client.get_file("greeting.txt")
      end
    end

    it "should delete a file" do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @http.stub!(:node).and_return(@client.nodes.first)
      @client.stub!(:http).and_yield(@http)
      @http.should_receive(:delete_file).with("greeting.txt")
      @client.delete_file("greeting.txt")
    end

    it "should detect if file exists via HTTP" do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @http.stub!(:node).and_return(@client.nodes.first)
      @client.stub!(:http).and_yield(@http)
      @http.should_receive(:file_exists?).and_return(true)
      @client.file_exists?("foo").should be_true
    end
  end

  describe "ssl", :ssl => true do
    before :each do
      @client = Riak::Client.new
    end

    it "should allow passing ssl options into the initializer" do
      lambda { client = Riak::Client.new(:ssl => {:verify_mode => "peer"}) }.should_not raise_error
    end

    it "should not have ssl options by default" do
      @client.nodes.first.ssl_options.should be_nil
    end

    it "should have a blank hash for ssl options if the protocol is set to https" do
      @client.protocol = 'https'
      @client.nodes.first.ssl_options.should be_a(Hash)
    end

    # The api should have an ssl= method for setting up all of the ssl
    # options.  Once the ssl options have been assigned via `ssl=` they should
    # be read back out using the read only `ssl_options`.  This is to provide
    # a seperate api for setting ssl options via client configuration and
    # reading them inside of a http backend.
    it "should not allow reading ssl options via ssl" do
      @client.should_not respond_to(:ssl)
    end

    it "should not allow writing ssl options via ssl_options=" do
      @client.should_not respond_to(:ssl_options=)
    end

    it "should allow setting ssl to true" do
      @client.ssl = true
      @client.nodes.first.ssl_options[:verify_mode].should eq('none')
    end

    it "should allow setting ssl options as a hash" do
      @client.ssl = {:verify_mode => "peer"}
      @client.nodes.first.ssl_options[:verify_mode].should eq('peer')
    end

    it "should set the protocol to https when setting ssl to true" do
      @client.ssl = true
      @client.protocol.should eq("https")
    end

    it "should set the protocol to http when setting ssl to false" do
      @client.protocol = 'https'
      @client.ssl = false
      @client.protocol.should eq('http')
    end

    it "should should clear ssl options when setting ssl to false" do
      @client.ssl = true
      @client.nodes.first.ssl_options.should_not be_nil
      @client.ssl = false
      @client.nodes.first.ssl_options.should be_nil
    end

    it "should set the protocol to https when setting ssl options" do
      @client.ssl = {:verify_mode => "peer"}
      @client.protocol.should eq("https")
    end

    it "should allow setting the verify_mode to none" do
      @client.ssl = {:verify_mode => "none"}
      @client.nodes.first.ssl_options[:verify_mode].should eq("none")
    end

    it "should allow setting the verify_mode to peer" do
      @client.ssl = {:verify_mode => "peer"}
      @client.nodes.first.ssl_options[:verify_mode].should eq("peer")
    end

    it "should not allow setting the verify_mode to anything else" do
      lambda {@client.ssl = {:verify_mode => :your_mom}}.should raise_error(ArgumentError)
    end

    it "should default verify_mode to none" do
      @client.ssl = true
      @client.nodes.first.ssl_options[:verify_mode].should eq("none")
    end

    it "should allow setting the pem" do
      @client.ssl = {:pem => 'i-am-a-pem'}
      @client.nodes.first.ssl_options[:pem].should eq('i-am-a-pem')
    end

    it "should set them pem from the contents of pem_file" do
      filepath = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test.pem'))
      @client.ssl = {:pem_file => filepath}
      @client.nodes.first.ssl_options[:pem].should eq("i-am-a-pem\n")
    end

    it "should allow setting the pem_password" do
      @client.ssl = {:pem_password => 'pem-pass'}
      @client.nodes.first.ssl_options[:pem_password].should eq('pem-pass')
    end

    it "should allow setting the ca_file" do
      @client.ssl = {:ca_file => '/path/to/ca.crt'}
      @client.nodes.first.ssl_options[:ca_file].should eq('/path/to/ca.crt')
    end

    it "should allow setting the ca_path" do
      @client.ssl = {:ca_path => '/path/to/certs/'}
      @client.nodes.first.ssl_options[:ca_path].should eq('/path/to/certs/')
    end

    %w[pem ca_file ca_path].each do |option|
      it "should default the verify_mode to peer when setting the #{option}" do
        @client.ssl = {option.to_sym => 'test-data'}
        @client.nodes.first.ssl_options[:verify_mode].should eq("peer")
      end

      it "should allow setting the verify mode when setting the #{option}" do
        @client.ssl = {option.to_sym => 'test-data', :verify_mode => "none"}
        @client.nodes.first.ssl_options[:verify_mode].should eq("none")
      end
    end
  end
end
