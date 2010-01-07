require 'rubygems' unless defined?(Gem)
require 'active_support' unless defined?(ActiveSupport)
require 'base64'

module Riak
  autoload :Client, "riak/client"
end
