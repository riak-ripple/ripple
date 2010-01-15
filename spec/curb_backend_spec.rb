# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require File.join(File.dirname(__FILE__), "spec_helper")

begin
  require 'curb'
rescue LoadError
  warn "Skipping CurbBackend specs, curb library not found."
else
  describe Riak::Client::CurbBackend do
    def setup_http_mock(method, uri, options={})
      method = method.to_s.upcase
      uri = URI.parse(uri)
      path = uri.path || "/"
      query = uri.query || ""
      status = options[:status] ? Array(options[:status]).first.to_i : 200
      body = options[:body] || []
      headers = options[:headers] || {}
      headers['Content-Type'] ||= "text/plain"
      $server.attach do |env|
        env["REQUEST_METHOD"].should == method
        env["PATH_INFO"].should == path
        env["QUERY_STRING"].should == query
        [status, headers, Array(body)]
      end
    end

    before :each do
      @client = Riak::Client.new(:port => 4000) # Point to our mock
      @backend = Riak::Client::CurbBackend.new(@client)
    end

    it_should_behave_like "HTTP backend"

    after :each do
      $server.detach
    end
  end
end