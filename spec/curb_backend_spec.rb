require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Client::CurbBackend do
  def setup_http_mock(method, uri, options={})
    method = method.to_s.upcase
    uri = URI.parse(uri)
    path = uri.path || "/"
    query = uri.query || ""
    status = options[:status] ? Array(options[:status]).first.to_i : 200
    body = options[:body] || []
    headers = options[:headers] || {}
    headers['Content-Type'] ||= "text/plain"
    $server.attach do |env|
      env["REQUEST_METHOD"].should == method
      env["PATH_INFO"].should == path
      env["QUERY_STRING"].should == query
      [status, headers, Array(body)]
    end
  end

  before :each do
    @client = Riak::Client.new(:port => 4000) # Point to our mock
    @backend = Riak::Client::CurbBackend.new(@client)
  end

  it_should_behave_like "HTTP backend"

  after :each do
    $server.detach
  end
end
