module Riak
  class Client
    class Pool
      # A re-entrant thread-safe resource pool. Generates new resources on
      # demand.
      
      require 'thread'

      attr_accessor :pool
      attr_accessor :open
      attr_accessor :close
      
      class Element
        # An element of the pool. Comprises an object with an owning thread.
        
        attr_accessor :object
        attr_accessor :owner

        def initialize(object, owner = nil)
          @object = object
          @owner = owner
        end

        def lock
          @owner = Thread.current
        end

        def unlock
          @owner = nil
        end
      end

      # Open is a callable which returns a new object for the pool. Close is
      # called with an object before it is freed.
      def initialize(open, close)
        @open = open
        @close = close
        @lock = Mutex.new

        # Pool is a hash of thread IDs to an array of objects in the pool.
        @pool = Set.new
      end

      # Acquire an element of the pool. Yields the object.
      def >>
        unless block_given?
          raise ArgumentError, "block required"
        end

        r = nil
        begin
          e = nil
          @lock.synchronize do
            if e = pool.find { |e| not e.owner }
              # An existing element is unlocked
            else
              # All lines are busy.
              pool << (e = Element.new(@open.call))
            end
            e.lock
          end

          r = yield e.object
        ensure
          # Unlock
          e.unlock
        end
        r
      end

      # Iterate over a snapshot of the set. May need to poll to complete.
      # Expensive!
      def each(poll_interval = 0.05)
        targets = @pool.to_a
        unlocked = []
        until targets.empty?
          @lock.synchronize do
            unlocked, targets = targets.partition do |e|
              if e.owner
                false
              else
                e.lock
                true
              end
            end
          end
          unlocked.each do |e|
            begin
              yield e.object
            ensure
              e.unlock
            end
          end
          sleep poll_interval
        end
      end
    end
  end
end
