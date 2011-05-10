# Load JSON
unless defined? JSON
  begin
    require 'yajl/json_gem'
  rescue LoadError
    require 'json'
  end
end

module Riak
  class << self
    # Options that will be passed to the JSON parser and encoder.
    # Defaults to {:max_nesting => 20}
    attr_accessor :json_options
  end
  self.json_options = {:max_nesting => 20}
end
