require 'spec_helper'

describe Riak::Client::NetHTTPBackend do
  before :each do
    @client = Riak::Client.new(:http_backend => :NetHTTP)
    @backend = @client.http
    FakeWeb.allow_net_connect = false
  end

  def setup_http_mock(method, uri, options={})
    FakeWeb.register_uri(method, uri, options)
  end

  it_should_behave_like "HTTP backend"

end
