require 'rubygems' unless defined?(Gem)
require 'active_support' unless defined?(ActiveSupport)

module Riak
  autoload :Client, "riak/client"
end
