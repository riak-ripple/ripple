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
  module Util
    # Methods for escaping URL segments.
    module Escape
      # CGI-escapes bucket or key names that may contain slashes for use in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def escape(bucket_or_key)
        CGI.escape(bucket_or_key.to_s).gsub("+", "%20")
      end
    end
  end
end
