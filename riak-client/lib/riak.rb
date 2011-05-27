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

  class << self
    # Only change this if you really know what you're doing. Better to
    # err on the side of caution and assume you don't.
    # @private
    attr_accessor :disable_list_keys_warnings
  end
  self.disable_list_keys_warnings = false
end
