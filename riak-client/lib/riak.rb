require 'riak/encoding'
require 'riak/core_ext'
require 'riak/client'
require 'riak/map_reduce'
require 'riak/util/translation'

# The Riak module contains all aspects of the client interface to
# Riak.
module Riak
  # Utility classes and mixins
  module Util; end
  extend Util::Translation
end
