require 'riak'

module Riak
  class Client
    class CurbBackend < HTTPBackend
      begin
        require 'curb'

        def initialize(client)
          super
          @curl = Curl::Easy.new
          @curl.follow_location = false
        end

        private
        def perform(method, uri, user_headers, expect, data=nil)
          # Setup
          @curl.headers = default_headers.merge(user_headers)
          @curl.url = uri.to_s
          response_headers = Headers.new
          @curl.on_header do |header_line|
            k,v = parse_header(header_line)
            response_headers.add_field(k,v) if k && v
            header_line.size
          end
          @curl.on_body {|chunk| yield chunk; chunk.size } if block_given?

          # Perform
          case method
          when :put, :post
            @curl.send("http_#{method}", data)
          else
            @curl.send("http_#{method}")
          end

          # Verify
          if @curl.response_code.to_i == expect.to_i
            result = { :headers => response_headers.to_hash }
            unless block_given? || method == :head
              result[:body] = @curl.body_str
            end
            result
          else
            raise FailedRequest.new(method, expect, @curl.response_code, response_headers.to_hash, @curl.body_str)
          end
        end

        def parse_header(chunk)
          line = chunk.strip
          # thanks Net::HTTPResponse
          return [nil,nil] if chunk =~ /\AHTTP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/in
          m = /\A([^:]+):\s*/.match(line)
          [m[1], m.post_match] rescue [nil, nil]
        end
      rescue LoadError
        warn "curb library not found! Riak::Client::CurbBackend will not work!"

        def perform(*args)
          raise NotImplementedError, "Riak::Client::CurbBackend could not find curb library!"
        end
      end

      class Headers
        include Net::HTTPHeader

        def initialize
          initialize_http_header({})
        end
      end
    end
  end
end
