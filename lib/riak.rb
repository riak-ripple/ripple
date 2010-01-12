require 'active_support'
require 'base64'
require 'uri'
require 'net/http'

module Riak
  autoload :Client, "riak/client"
  autoload :Bucket, "riak/bucket"
end
