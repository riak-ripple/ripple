require 'riak'

module Riak
  class Client
    class NetHTTPBackend < HTTPBackend
      private
      def perform(method, uri, user_headers, expect, data=nil)
        headers = default_headers.merge(user_headers)

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
