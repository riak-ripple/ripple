require 'rack'
require 'riak/session_store'

if defined?(ActionDispatch)
  require 'ripple/session_store'
  ActionDispatch::Session::RiakStore = Ripple::SessionStore
end
