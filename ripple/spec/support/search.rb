require 'support/test_server'

class Riak::TestServer
  # For now this is a local hack - later we'll make it global.
  def riak_search?
    (s = status) && s['riak_search_version']
  end
end

RSpec.configure do |config|
  config.before(:all, :search => true) do
    pending("depends upon riak search, which is not available") unless $test_server.riak_search?
  end
end
