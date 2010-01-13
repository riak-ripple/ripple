require 'active_support'
require 'base64'
require 'uri'
require 'net/http'

module Riak
  # Domain objects
  autoload :Binary,   "riak/binary"
  autoload :Bucket,   "riak/bucket"
  autoload :Client,   "riak/client"
  autoload :Document, "riak/document"
  autoload :Link,     "riak/link"
  autoload :Object,   "riak/object"
  
  # Exceptions
  autoload :FailedRequest, "riak/failed_request"
  autoload :InvalidResponse, "riak/invalid_response"
end
