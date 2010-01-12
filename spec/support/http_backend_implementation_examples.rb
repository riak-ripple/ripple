shared_examples_for "HTTP backend" do
  describe "HEAD requests" do
    before :each do
      setup_http_mock(:head, @backend.path("foo").to_s, :body => "")
    end

    it "should return only the headers when the request succeeds" do
      response = @backend.head(200, "foo")
      response[:body].should be_nil
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.head(301, "foo") }.should raise_error(Riak::FailedRequest)
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.head(200) }.should raise_error(ArgumentError)
    end
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
      lambda { @backend.get(304, "foo") }.should raise_error(Riak::FailedRequest)
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

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.get(200) }.should raise_error(ArgumentError)
    end
  end

  describe "DELETE requests" do
    before :each do
      setup_http_mock(:delete, @backend.path("foo").to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.delete(200, "foo")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.delete(304, "foo") }.should raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.delete(200, "foo") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response[:body].should be_nil
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.delete(200) }.should raise_error(ArgumentError)
    end
  end

  describe "PUT requests" do
    before :each do
      setup_http_mock(:put, @backend.path("foo").to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.put(200, "foo", "This is the body.")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.put(204, "foo", "This is the body.") }.should raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.put(200, "foo", "This is the body.") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response[:body].should be_nil
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.put(200) }.should raise_error(ArgumentError)
    end

    it "should raise an error if no body data is given" do
      lambda { @backend.put(200, "foo") }.should raise_error(ArgumentError)
    end

    it "should raise an error if the body is not a string" do
      lambda { @backend.put(200, "foo", 123) }.should raise_error(ArgumentError)
    end
  end

  describe "POST requests" do
    before :each do
      setup_http_mock(:post, @backend.path("foo").to_s, :body => "Success!")
    end

    it "should return the response body and headers when the request succeeds" do
      response = @backend.post(200, "foo", "This is the body.")
      response[:body].should == "Success!"
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise a FailedRequest exception when the request fails" do
      lambda { @backend.post(204, "foo", "This is the body.") }.should raise_error(Riak::FailedRequest)
    end

    it "should yield successive chunks of the response to the given block but not return the entire body" do
      chunks = ""
      response = @backend.post(200, "foo", "This is the body.") do |chunk|
        chunks << chunk
      end
      chunks.should == "Success!"
      response[:body].should be_nil
      response[:headers].should be_kind_of(Hash)
    end

    it "should raise an error if an invalid resource path is given" do
      lambda { @backend.post(200) }.should raise_error(ArgumentError)
    end

    it "should raise an error if no body data is given" do
      lambda { @backend.post(200, "foo") }.should raise_error(ArgumentError)
    end

    it "should raise an error if the body is not a string" do
      lambda { @backend.post(200, "foo", 123) }.should raise_error(ArgumentError)
    end
  end
end
