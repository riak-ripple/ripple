require 'riak'

module Riak
  class InvalidResponse < StandardError
    def initialize(expected, received, extra="")
      expected = expected.inspect if Hash === expected
      received = received.inspect if Hash === received
      super "Expected #{expected} but received #{received} from Riak #{extra}"
    end
  end
end
