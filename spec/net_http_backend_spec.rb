require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Client::NetHTTPBackend do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::NetHTTPBackend.new(@client)
    FakeWeb.allow_net_connect = false
  end

  def setup_http_mock(method, uri, options={})
    FakeWeb.register_uri(method, uri, options)
  end
  
  it_should_behave_like "HTTP backend"
end
