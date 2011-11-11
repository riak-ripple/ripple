shared_examples_for "HTTP backend" do
  let(:resource){ @backend.path("/riak/","foo") }

  describe "HEAD requests" do
    before :each do
      setup_http_mock(:head, resource.to_s, :body => "")
    end

    it "should return only the headers when the request succeeds" do
      response = @backend.head(200, resource)
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.head(301, resource) }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.head([200, 301], resource) }.should_not raise_error(Riak::FailedRequest)
    end
  end

  describe "GET requests" do
    before :each do
      setup_http_mock(:get, resource.to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.get(200, resource)
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.get(304, resource) }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.get([200, 301], resource) }.should_not raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.get(200, resource) do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end
  end

  describe "DELETE requests" do
    before :each do
      setup_http_mock(:delete, resource.to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.delete(200, resource)
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.delete(304, resource) }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.delete([200, 301], resource) }.should_not raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.delete(200, resource) do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end
  end

  describe "PUT requests" do
    before :each do
      setup_http_mock(:put, resource.to_s, :body => "Success!")
    end

    it "should return the response body, headers, and code when the request succeeds" do
      response = @backend.put(200, resource, "This is the body.")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.put(204, resource, "This is the body.") }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.put([200, 204], resource, "This is the body.") }.should_not raise_error(Riak::FailedRequest)
    end


    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.put(200, resource, "This is the body.") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end


    it "should raise an error if no body data is given" do
      lambda { @backend.put(200, resource) }.should raise_error(ArgumentError)
    end

    it "should raise an error if the body is not a string or IO" do
      lambda { @backend.put(200, resource, 123) }.should raise_error(ArgumentError)
    end
  end

  describe "POST requests" do
    before :each do
      setup_http_mock(:post, resource.to_s, :body => "Success!")
    end

    it "should return the response body, headers, and code when the request succeeds" do
      response = @backend.post(200, resource, "This is the body.")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.post(204, resource, "This is the body.") }.should raise_error(Riak::FailedRequest)
    end

    it "should not raise a FailedRequest if one of the expected response codes matches" do
      lambda { @backend.post([200, 204], resource, "This is the body.") }.should_not raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.post(200, resource, "This is the body.") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response.should_not have_key(:body)
      response[:headers].should be_kind_of(Hash)
      response[:code].should == 200
    end

    it "should raise an error if no body data is given" do
      lambda { @backend.post(200, resource) }.should raise_error(ArgumentError)
    end

    it "should raise an error if the body is not a string or IO" do
      lambda { @backend.post(200, resource, 123) }.should raise_error(ArgumentError)
    end
  end

  describe "Responses with no body" do
    [204, 205, 304].each do |code|
      [:get, :post, :put, :delete].each do |method|
        it "should not return a body on #{method.to_s.upcase} for #{code}" do
          setup_http_mock(method, resource.to_s, :status => code)
          response = if method == :post || method == :put
                       @backend.send(method, code, resource, "This is the body")
                     else
                       @backend.send(method, code, resource)
                     end
          response.should_not have_key(:body)
        end
      end
    end
  end

  describe "SSL" do
    it "should be supported" do
      unless @client.http_backend == :NetHTTP
        @client.nodes.each do |node|
          node.http_port = $mock_server.port + 1
        end
      end
      @client.ssl = true
      setup_http_mock(:get, @backend.path("/riak/","ssl").to_s, :body => "Success!")
      response = @backend.get(200,  @backend.path("/riak/","ssl"))
      response[:code].should == 200
    end
  end

  describe "HTTP Basic Authentication", :basic_auth => true do
    it "should add the http basic auth header" do
      @client.basic_auth = "ripple:rocks"
      if @client.http_backend == :NetHTTP
        setup_http_mock(:get, "http://ripple:rocks@127.0.0.1:8098/riak/auth", :body => 'Success!')
      else
        @_mock_set = "Basic #{Base64::encode64("ripple:rocks").strip}"
        $mock_server.attach do |env|
          $mock_server.satisfied = env['HTTP_AUTHORIZATION'] == @_mock_set
          [200, {}, Array('Success!')]
        end
      end
      response = @backend.get(200, @backend.path("/riak/", "auth"))
      response[:code].should == 200
    end
  end

  describe "Invalid responses" do

    def bad_request(method)
      if method == :post || method == :put
        @backend.send(method, 200, resource, "body")
      else
        @backend.send(method, 200, resource)
      end
    end

    [:get, :post, :put, :delete].each do |method|
      context method.to_s do

        before(:each) do
          setup_http_mock(method, resource.to_s, :body => "Failure!", :status => 400, 'Content-Type' => 'text/plain' )
        end

        it "raises an HTTPFailedRequest exeption" do
          lambda { bad_request(method) }.should raise_error(Riak::HTTPFailedRequest)
        end

        it "should normalize the response header keys to lower case" do
          begin
            bad_request(method)
          rescue Riak::HTTPFailedRequest => fr
            fr.headers.keys.should =~ fr.headers.keys.collect(&:downcase)
          else
            fail "No exception raised!"
          end
        end

      end
    end

  end

end
