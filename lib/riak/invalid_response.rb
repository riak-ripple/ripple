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
require 'riak'

module Riak
  # Raised when Riak returns a response that is in an unexpected format
  class InvalidResponse < StandardError
    def initialize(expected, received, extra="")
      expected = expected.inspect if Hash === expected
      received = received.inspect if Hash === received
      super "Expected #{expected} but received #{received} from Riak #{extra}"
    end
  end
end
