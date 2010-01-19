# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'active_support'
require 'base64'
require 'uri'
require 'net/http'
require 'yaml'

module Riak
  # Domain objects
  autoload :Bucket,          "riak/bucket"
  autoload :Client,          "riak/client"
  autoload :Link,            "riak/link"
  autoload :WalkSpec,        "riak/walk_spec"

  autoload :RObject,         "riak/robject"
  autoload :Document,        "riak/document"
  autoload :Binary,          "riak/binary"

  # Exceptions
  autoload :FailedRequest,   "riak/failed_request"
  autoload :InvalidResponse, "riak/invalid_response"

  module Util
    autoload :Headers,       "riak/util/headers"
    autoload :Multipart,     "riak/util/multipart"
  end
end

# Necessary so that load-order is correct
require 'riak/robject'
