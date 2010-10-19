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
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::Client do
  describe "when initializing" do
    it "should default to the local interface on port 8098" do
      client = Riak::Client.new
      client.host.should == "127.0.0.1"
      client.port.should == 8098
    end

    it "should accept a host" do
      client = Riak::Client.new :host => "riak.basho.com"
      client.host.should == "riak.basho.com"
    end

    it "should accept a port" do
      client = Riak::Client.new :port => 9000
      client.port.should == 9000
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

    it "should default the prefix to /riak/ if not specified" do
      Riak::Client.new.prefix.should == "/riak/"
    end

    it "should accept a mapreduce path" do
      client = Riak::Client.new(:mapred => "/mr")
      client.mapred.should == "/mr"
    end

    it "should default the mapreduce path to /mapred if not specified" do
      Riak::Client.new.mapred.should == "/mapred"
    end

    it "should accept a luwak path" do
      client = Riak::Client.new(:luwak => "/beans")
      client.luwak.should == "/beans"
    end

    it "should default the luwak path to /luwak if not specified" do
      Riak::Client.new.luwak.should == "/luwak"
    end
  end

  describe "reconfiguring" do
    before :each do
      @client = Riak::Client.new
    end

    describe "setting the host" do
      it "should allow setting the host" do
        @client.should respond_to(:host=)
        @client.host = "riak.basho.com"
        @client.host.should == "riak.basho.com"
      end

      it "should require the host to be an IP or hostname" do
        [238472384972, ""].each do |invalid|
          lambda { @client.host = invalid }.should raise_error(ArgumentError)
        end
        ["127.0.0.1", "10.0.100.5", "localhost", "otherhost.local", "riak.basho.com"].each do |valid|
          lambda { @client.host = valid }.should_not raise_error
        end
      end
    end

    describe "setting the port" do
      it "should allow setting the port" do
        @client.should respond_to(:port=)
        @client.port = 9000
        @client.port.should == 9000
      end

      it "should require the port to be a valid number" do
        [-1,65536,"foo"].each do |invalid|
          lambda { @client.port = invalid }.should raise_error(ArgumentError)
        end
        [0,1,65535,8098].each do |valid|
          lambda { @client.port = valid }.should_not raise_error
        end
      end
    end

    it "should allow setting the prefix (although we prefer the raw interface)" do
      @client.should respond_to(:prefix=)
      @client.prefix = "/another-prefix"
      @client.prefix.should == "/another-prefix"
    end

    describe "setting the client id" do
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
  end

  describe "choosing an HTTP backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "should choose the Curb backend if Curb is available" do
      @client.should_receive(:require).with('curb').and_return(true)
      @client.http.should be_instance_of(Riak::Client::CurbBackend)
    end

    it "should choose the Net::HTTP backend if Curb is unavailable" do
      @client.should_receive(:require).with('curb').and_raise(LoadError)
      @client.should_receive(:warn).and_return(true)
      @client.http.should be_instance_of(Riak::Client::NetHTTPBackend)
    end
  end

  describe "retrieving a bucket" do
    before :each do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @client.stub!(:http).and_return(@http)
      @payload = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
      @http.stub!(:get).and_return(@payload)
    end

    it "should send a GET request to the bucket name and return a Riak::Bucket" do
      @http.should_receive(:get).with(200, "/riak/", "foo", {:keys => false}, {}).and_return(@payload)
      @client.bucket("foo").should be_kind_of(Riak::Bucket)
    end

    it "should allow requesting bucket properties with the keys" do
      @http.should_receive(:get).with(200, "/riak/", "foo", {:keys => true}, {}).and_return(@payload)
      @client.bucket("foo", :keys => true)
    end

    it "should escape bucket names with invalid characters" do
      @http.should_receive(:get).with(200, "/riak/", "foo%2Fbar%20", {:keys => false}, {}).and_return(@payload)
      @client.bucket("foo/bar ", :keys => false)
    end
  end

  describe "storing a file" do
    before :each do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @client.stub!(:http).and_return(@http)
    end

    it "should store the file in Luwak and return the key/filename when no filename is given" do
      @http.should_receive(:post).with(201, "/luwak", anything, {"Content-Type" => "text/plain"}).and_return(:code => 201, :headers => {"location" => ["/luwak/123456789"]})
      @client.store_file("text/plain", "Hello, world").should == "123456789"
    end

    it "should store the file in Luwak and return the key/filename when the filename is given" do
      @http.should_receive(:put).with(204, "/luwak", "greeting.txt", anything, {"Content-Type" => "text/plain"}).and_return(:code => 204, :headers => {})
      @client.store_file("greeting.txt", "text/plain", "Hello, world").should == "greeting.txt"
    end
  end

  describe "retrieving a file" do
    before :each do
      @client = Riak::Client.new
      @http = mock(Riak::Client::HTTPBackend)
      @client.stub!(:http).and_return(@http)
      @http.should_receive(:get).with(200, "/luwak", "greeting.txt").and_yield("Hello,").and_yield(" world!").and_return({:code => 200, :headers => {"content-type" => ["text/plain"]}})
    end

    it "should stream the data to a temporary file" do
      file = @client.get_file("greeting.txt")
      file.open {|f| f.read.should == "Hello, world!" }
    end

    it "should stream the data through the given block, returning nil" do
      string = ""
      result = @client.get_file("greeting.txt"){|chunk| string << chunk }
      result.should be_nil
      string.should == "Hello, world!"
    end

    it "should expose the original key and content-type on the temporary file" do
      file = @client.get_file("greeting.txt")
      file.content_type.should == "text/plain"
      file.original_filename.should == "greeting.txt"
    end
  end

  it "should delete a file" do
    @client = Riak::Client.new
    @http = mock(Riak::Client::HTTPBackend)
    @client.stub!(:http).and_return(@http)
    @http.should_receive(:delete).with([204,404], "/luwak", "greeting.txt")
    @client.delete_file("greeting.txt")
  end
  
  it "should return true if the file exists" do
    @client = Riak::Client.new
    @client.http.should_receive(:head).and_return(:code => 200)
    @client.file_exists?("foo").should be_true
  end
  
  it "should return false if the file doesn't exist" do
    @client = Riak::Client.new
    @client.http.should_receive(:head).and_return(:code => 404)
    @client.file_exists?("foo").should be_false
  end

  it "should escape the filename when storing, retrieving or deleting files" do
    @client = Riak::Client.new
    @http = mock(Riak::Client::HTTPBackend)
    @client.stub!(:http).and_return(@http)
    # Delete escapes keys
    @http.should_receive(:delete).with([204,404], "/luwak", "docs%2FA%20Big%20PDF.pdf")
    @client.delete_file("docs/A Big PDF.pdf")
    # Get escapes keys
    @http.should_receive(:get).with(200, "/luwak", "docs%2FA%20Big%20PDF.pdf").and_yield("foo").and_return(:headers => {"content-type" => ["text/plain"]}, :code => 200)
    @client.get_file("docs/A Big PDF.pdf")
    # Streamed get escapes keys
    @http.should_receive(:get).with(200, "/luwak", "docs%2FA%20Big%20PDF.pdf").and_yield("foo").and_return(:headers => {"content-type" => ["text/plain"]}, :code => 200)
    @client.get_file("docs/A Big PDF.pdf"){|chunk| chunk }
    # Put escapes keys
    @http.should_receive(:put).with(204, "/luwak", "docs%2FA%20Big%20PDF.pdf", "foo", {"Content-Type" => "text/plain"})
    @client.store_file("docs/A Big PDF.pdf", "text/plain", "foo")
  end
end
