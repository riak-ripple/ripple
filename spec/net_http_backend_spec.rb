require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Client::NetHTTPBackend do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::NetHTTPBackend.new(@client)
  end

  def setup_http_mock(method, uri, options={})
    FakeWeb.register_uri(method, uri, options)
  end
  
  describe "GET requests" do
    before :each do
      setup_http_mock(:get, @backend.path("foo").to_s, :body => "Success!")
    end
    
    it "should return the response body and headers when the request succeeds" do      
      response = @backend.get(200, "foo")      
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.get(304, "foo") }.should raise_error(Riak::Client::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.get(200, "foo") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response[:body].should be_nil
      response[:headers].should be_kind_of(Hash)
    end
  end
#   describe "PUT requests"
#   describe "POST requests"
#   describe "DELETE requests"
end
