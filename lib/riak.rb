require 'active_support'
require 'base64'
require 'uri'
require 'net/http'

module Riak
  # Domain objects
  autoload :Bucket,   "riak/bucket"
  autoload :Client,   "riak/client"
  autoload :Document, "riak/document"
  autoload :Binary,   "riak/binary"
  autoload :Object,   "riak/object"
  
  # Exceptions
  autoload :FailedRequest, "riak/failed_request"
  autoload :InvalidResponse, "riak/invalid_response"
end
