require 'riak'

module Riak
  class Client
    # Uses the Ruby standard library Net::HTTP to connect to Riak.
    # We recommend using the CurbBackend, which will
    # be preferred when the 'curb' library is available.
    # Conforms to the Riak::Client::HTTPBackend interface.
    class NetHTTPBackend < HTTPBackend
      private
      def perform(method, uri, headers, expect, data=nil) #:nodoc:
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send(method, *([uri.request_uri, data, headers].compact))
          if response.code.to_i == expect.to_i
            result = {:headers => response.to_hash}
            if block_given?
              response.read_body {|chunk| yield chunk }
            elsif method != :head
              result[:body] = response.body
            end
            result
          else
            raise FailedRequest.new(method, expect, response.code, response.to_hash, response.body)
          end
        end
      end
    end
  end
end
