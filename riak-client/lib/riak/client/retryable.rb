module Riak
  class Client
    # Encapsulates request retry logic. Included in backends directly,
    # not really for public use.
    module Retryable
      # Perform a client request with a number of retries.
      # @param [Hash] options flags for modifying the retry logic
      # @option options [Fixnum] :retries the maximum number of times
      #     to retry
      def with_retries(options={})
        retries = options[:retries] || 3
        begin
          yield
        rescue => exception
          raise unless retries > 0 && retryable?(exception, options)
          retries -= 1
          refresh_connection(exception)
          retry
        end
      end

      # Backends should reimplement this to select what types of
      # exceptions are retryable. Called internally by {#with_retries}
      # @param [Exception] exception the exception that was raised
      # @param [Hash] options flags for modifying the retry logic
      def retryable?(exception, options={})
        false
      end

      # Backends should reimplement this to get a new connection if
      # the exception is one that requires it.
      # @param [Exception] exception the exception that was raised
      def refresh_connection(exception)
      end
    end
  end
end
