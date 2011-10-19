
begin
  require 'fiber'
rescue LoadError
  require 'riak/util/fiber1.8'
end

module Riak
  class Client
    # @private
    class Pump
      def initialize(block)
        @fiber = Fiber.new do
          loop do
            block.call Fiber.yield
          end
        end
        @fiber.resume
      end

      def pump(input)
        @fiber.resume input
      end

      def to_proc
        method(:pump).to_proc
      end
    end
  end
end
