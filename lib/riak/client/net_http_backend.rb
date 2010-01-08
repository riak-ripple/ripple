require 'riak'

module Riak
  class Client
    class NetHTTPBackend < HTTPBackend
      def head(expect, *resource)
        headers = resource.extract_options!
        verify_path!(resource)
        perform(:head, path(*resource), headers, expect)
      end

      def get(expect, *resource, &block)
        headers = resource.extract_options!
        verify_path!(resource)
        perform(:get, path(*resource), headers, expect, &block)
      end

      def put(expect, *resource, &block)
        headers = resource.extract_options!               
        uri, data = verify_path_and_body!(resource)
        perform(:put, path(*uri), headers, expect, data, &block)
      end

      def post(expect, *resource, &block)
        headers = resource.extract_options!
        uri, data = verify_path_and_body!(resource)
        perform(:post, path(*uri), headers, expect, data, &block)
      end

      def delete(expect, *resource, &block)
        headers = resource.extract_options!
        verify_path!(resource)
        perform(:delete, path(*resource), headers, expect, &block)
      end

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
