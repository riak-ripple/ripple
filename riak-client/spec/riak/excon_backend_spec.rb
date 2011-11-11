require 'spec_helper'

begin
  require 'excon'
rescue LoadError
  warn "Skipping ExconBackend specs, excon library not found."
else
  $mock_server = DrbMockServer
  $mock_server.maybe_start

  describe Riak::Client::ExconBackend do
    def setup_http_mock(method, uri, options={})
      method  = method.to_s.upcase
      uri     = URI.parse(uri)
      path    = uri.path          || "/"
      query   = uri.query         || ""
      body    = options[:body]    || []
      headers = options[:headers] || {}
      headers['Content-Type']     ||= "text/plain"
      status  = options[:status] ? Array(options[:status]).first.to_i : 200
      @_mock_set = [status, headers, method, path, query, body]
      $mock_server.expect(*@_mock_set)
    end

    before :each do
      @client = Riak::Client.new(:http_port => $mock_server.port, :http_backend => :Excon) # Point to our mock
      @node = @client.node
      @backend = @client.new_http_backend
      @_mock_set = false
    end

    after :each do
      if @_mock_set
        $mock_server.satisfied.should be_true("Expected #{@_mock_set.inspect}, failed")
      end
    end

    it_should_behave_like "HTTP backend"

    it "should split long headers into 8KB chunks" do
      # TODO: This doesn't actually inspect the emitted headers. How
      # can it?
      setup_http_mock(:put, @backend.path("/riak/","foo").to_s, :body => "ok")
      lambda do
        @backend.put(200, @backend.path("/riak", "foo"), "body", {"Long-Header" => (["12345678"*10]*100).join(", ") })
      end.should_not raise_error
    end

    it "should support IO objects as the request body" do
      file = File.open(File.expand_path("../../fixtures/cat.jpg", __FILE__), 'rb')
      lambda do
        setup_http_mock(:put, @backend.path("/riak/","foo").to_s, :body => "ok")
        @backend.put(200, @backend.path("/riak/","foo"), file)
        $mock_server.satisfied.should be_true
      end.should_not raise_error
      file.rewind # Have to rewind the file or we hang
      lambda do
        setup_http_mock(:post, @backend.path("/riak/","foo").to_s, :body => "ok")
        @backend.post(200, @backend.path("/riak/", "foo"), file)
        $mock_server.satisfied.should be_true
      end.should_not raise_error
    end
  end

end
