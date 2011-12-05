require 'ripple/test_server'

Before do
  Ripple::TestServer.setup
end

After do
  Ripple::TestServer.clear
end
