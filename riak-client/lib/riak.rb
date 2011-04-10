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
$KCODE = "UTF8" if RUBY_VERSION < "1.9"

require 'riak/core_ext'
require 'riak/client'
require 'riak/map_reduce'

# The Riak module contains all aspects of the client interface to
# Riak.
module Riak
  # Utility classes and mixins
  module Util
  end
end
