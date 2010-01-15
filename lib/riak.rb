require 'active_support'
require 'base64'
require 'uri'
require 'net/http'
require 'yaml'

module Riak
  # Domain objects
  autoload :Bucket,   "riak/bucket"
  autoload :Client,   "riak/client"
  autoload :Link,     "riak/link"

  autoload :RObject,   "riak/robject"
  autoload :Document, "riak/document"
  autoload :Binary,   "riak/binary"

  # Exceptions
  autoload :FailedRequest, "riak/failed_request"
  autoload :InvalidResponse, "riak/invalid_response"
end

# Necessary so that load-order is correct
require 'riak/robject'
