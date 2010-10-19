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
require 'riak'
require 'rack/session/abstract/id'

module Riak
  # Lets you store web application session data in Riak.
  # Useful for those cases where you need more than the 4K that
  # cookies provide.
  #
  # Usage (Rack builder):
  #   use Riak::SessionStore
  #
  # Usage (Rails):
  #   config.middleware.use Riak::SessionStore
  #
  # For configuration options, see #initialize.
  class SessionStore < Rack::Session::Abstract::ID
    DEFAULT_OPTIONS = Rack::Session::Abstract::ID::DEFAULT_OPTIONS.merge \
      :host => "127.0.0.1",
      :port => 8098,
      :bucket => "_sessions",
      :r => 1,
      :w => 1,
      :dw => 0,
      :rw => 1,
      :n_val => 2,
      :last_write_wins => false


    attr_reader :bucket

    # Creates a new Riak::SessionStore middleware
    # @param app the Rack application
    # @param [Hash] options configuration options
    # @see Rack::Session::Abstract::ID#initialize
    def initialize(app, options={})
      super
      @client = Riak::Client.new(default_options.slice(:host,:port))
      # @client.http.send(:curl).verbose = true
      @bucket = @client.bucket(default_options[:bucket]).tap do |b|
        new_props = {}
        [:r,:w,:dw,:rw,:n_val].each do |q|
          new_props[q.to_s] = default_options[q] unless b.send(q) == default_options[q]
        end
        b.props = new_props unless new_props.blank?
      end
      self
    end

    def generate_sid
      loop do
        sid = super
        break sid unless @bucket.exists?(sid)
      end
    end

    private
    def get_session(env, session_id)
      unless session_id && robject = (bucket.get(session_id) rescue nil)
        session_id, robject = generate_sid, bucket.new
        robject.key = session_id
        robject.data = {}
        robject.store
      end
      [session_id, robject.data]
    end

    def set_session(env, session_id, session, options)
      if options[:renew] or options[:drop]
        bucket.delete(session_id)
        return false if options[:drop]
        session_id = generate_sid
      end
      robject = bucket.get_or_new(session_id)
      robject.data = session
      robject.store
      session_id
    rescue Riak::FailedRequest
      env['rack.errors'].puts $!.inspect
      false
    end
  end
end
