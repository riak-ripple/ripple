require 'thread'

module Riak
  class Client
    # A re-entrant thread-safe resource pool. Generates new resources on
    # demand.
    # @private
    class Pool
      # Raised when a taken element should be deleted from the pool.
      class BadResource < RuntimeError
      end

      # An element of the pool. Comprises an object with an owning
      # thread.
      # @private
      class Element
        attr_accessor :object
        attr_accessor :owner
        def initialize(object)
          @object = object
          @owner = owner
        end

        # Claims this element of the pool for the current Thread.
        def lock
          self.owner = Thread.current
        end
        
        # Is this element locked/claimed?
        def locked?
          not owner.nil?
        end

        # Releases this element of the pool from the current Thread.
        def unlock
          self.owner = nil
        end

        # Is this element available for use?
        def unlocked?
          owner.nil?
        end
      end
      
      attr_accessor :pool
      attr_accessor :open
      attr_accessor :close

      # Open is a callable which returns a new object for the pool. Close is
      # called with an object before it is freed.
      def initialize(open, close)
        @open = open
        @close = close
        @lock = Mutex.new
        @iterator = Mutex.new
        @element_released = ConditionVariable.new
        @pool = Set.new
      end

      # On each element of the pool, calls close(element) and removes it.
      # @private
      def clear
        each_element do |e|
          @close.call(e.object)
          
          # Remove the element from the pool.
          @lock.synchronize do
            @pool.delete e
          end 
        end
      end
      alias :close :clear

      # Locks each element in turn and closes/deletes elements for which the
      # object passes the block.
      def delete_if
        raise ArgumentError, "block required" unless block_given?

        each_element do |e|
          if yield e.object
            @close.call(e.object)
            
            @lock.synchronize do
              @pool.delete e
            end
          end
        end
      end

      # Acquire an element of the pool. Yields the object. If all
      # elements are claimed, it will create another one.
      # @yield [obj] a block that will perform some action with the
      #   element of the pool
      # @yieldparam [Object] obj an element of the pool, as created by
      #   the {#open} block
      # @private
      def take
        unless block_given?
          raise ArgumentError, "block required"
        end

        r = nil
        begin
          e = nil
          @lock.synchronize do
            e = pool.find { |e| e.unlocked? }
            unless e
              e = Element.new(@open.call)
              pool << e
            end
            e.lock
          end

          r = yield e.object
        rescue BadResource
          @lock.synchronize do
            @pool.delete e
          end
          raise
        ensure
          # Unlock
          e.unlock
          @element_released.signal
        end
        r
      end
      alias >> take
      
      # Iterate over a snapshot of the pool. Yielded objects are locked for the
      # duration of the block. This may block the current thread until elements
      # are released by other threads.
      # @private
      def each_element
        targets = @pool.to_a
        unlocked = []

        @iterator.synchronize do
          until targets.empty?
            @lock.synchronize do
              unlocked, targets = targets.partition {|e| e.unlocked? }
              unlocked.each {|e| e.lock }
            end

            unlocked.each do |e|
              begin
                yield e
              ensure
                e.unlock
              end
            end
            @element_released.wait(@iterator) unless targets.empty?
          end
        end
      end

      # As each_element, but yields objects, not wrapper elements.
      def each
        each_element do |e|
          yield e.object
        end
      end

      def size
        @lock.synchronize { @pool.size }
      end
    end
  end
end
