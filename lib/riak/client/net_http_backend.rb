require 'riak'

module Riak
  class Client
    class NetHTTPBackend < HTTPBackend
      def get(expect, *resource, &block)
        headers = resource.extract_options!        
        perform(:get, path(*resource), headers, expect, &block)
      end
      
      private
      def perform(method, uri, user_headers, expect, data=nil)
        headers = default_headers.merge(user_headers)

        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send(method, *([uri.request_uri, data, headers].compact))
          if response.code.to_s == expect.to_s
            if block_given?
              response.read_body {|chunk| yield chunk }
              {:headers => response.to_hash}
            else
              {:body => response.body, :headers => response.to_hash}
            end
          else
            raise FailedRequest.new(method, expect, response.code, response.to_hash, response.body)
          end
        end
      end
    end
  end
end
