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
shared_examples_for "HTTP backend" do
  describe "HEAD requests" do
    before :each do
      setup_http_mock(:head, @backend.path("/riak/","foo").to_s, :body => "")
    end

    it "should return only the headers when the request succeeds" do
      response = @backend.head(200, "/riak/","foo")
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.head(301, "/riak/", "foo") }.should raise_error(Riak::FailedRequest)
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.head(200, "/riak/") }.should raise_error(ArgumentError)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.head([200, 301], "/riak/", "foo") }.should_not raise_error(Riak::FailedRequest)
    end
  end

  describe "GET requests" do
    before :each do
      setup_http_mock(:get, @backend.path("/riak/","foo").to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.get(200, "/riak/","foo")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.get(304, "/riak/","foo") }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.get([200, 301], "/riak/","foo") }.should_not raise_error(Riak::FailedRequest)
    end
    
    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.get(200, "/riak/","foo") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.get(200, "/riak/") }.should raise_error(ArgumentError)
    end
  end

  describe "DELETE requests" do
    before :each do
      setup_http_mock(:delete, @backend.path("/riak/","foo").to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.delete(200, "/riak/","foo")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.delete(304, "/riak/","foo") }.should raise_error(Riak::FailedRequest)
    end
    
    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.delete([200, 301], "/riak/","foo") }.should_not raise_error(Riak::FailedRequest)
    end
    
    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.delete(200, "/riak/","foo") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.delete(200, "/riak/") }.should raise_error(ArgumentError)
    end
  end

  describe "PUT requests" do
    before :each do
      setup_http_mock(:put, @backend.path("/riak/","foo").to_s, :body => "Success!")
    end

    it "should return the response body, headers, and code when the request succeeds" do
      response = @backend.put(200, "/riak/","foo", "This is the body.")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.put(204, "/riak/","foo", "This is the body.") }.should raise_error(Riak::FailedRequest)
    end
    
    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.put([200, 204], "/riak/","foo", "This is the body.") }.should_not raise_error(Riak::FailedRequest)
    end
    
    
    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.put(200, "/riak/","foo", "This is the body.") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.put(200, "/riak/") }.should raise_error(ArgumentError)
    end

    it "should raise an error if no body data is given" do
      lambda { @backend.put(200, "/riak/","foo") }.should raise_error(ArgumentError)
    end

    it "should raise an error if the body is not a string" do
      lambda { @backend.put(200, "/riak/","foo", 123) }.should raise_error(ArgumentError)
    end
  end

  describe "POST requests" do
    before :each do
      setup_http_mock(:post, @backend.path("/riak/","foo").to_s, :body => "Success!")
    end

    it "should return the response body, headers, and code when the request succeeds" do
      response = @backend.post(200, "/riak/","foo", "This is the body.")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.post(204, "/riak/", "foo", "This is the body.") }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.post([200, 204], "/riak/", "foo", "This is the body.") }.should_not raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.post(200, "/riak/", "foo", "This is the body.") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.post(200, "/riak/") }.should raise_error(ArgumentError)
    end

    it "should raise an error if no body data is given" do
      lambda { @backend.post(200, "/riak/", "foo") }.should raise_error(ArgumentError)
    end

    it "should raise an error if the body is not a string" do
      lambda { @backend.post(200, "/riak/", "foo", 123) }.should raise_error(ArgumentError)
    end
  end

  describe "Responses with no body" do
    [204, 205, 304].each do |code|
      [:get, :post, :put, :delete].each do |method|
        it "should not return a body on #{method.to_s.upcase} for #{code}" do
          setup_http_mock(method, @backend.path("/riak/","foo").to_s, :status => code)
          response = if method == :post || method == :put
                       @backend.send(method, code,"/riak/","foo", "This is the body")
                     else
                       @backend.send(method, code, "/riak/", "foo")
                     end
          response.should_not have_key(:body)
        end
      end
    end
  end
end
