
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
  # Usage (Rails 2.3), requires you to swap out the default store:
  #   config.middleware.swap ActionController::Session::CookieStore, Riak::SessionStore
  #
  # For configuration options, see #initialize.
  class SessionStore < Rack::Session::Abstract::ID
    DEFAULT_OPTIONS = Rack::Session::Abstract::ID::DEFAULT_OPTIONS.merge \
    :host => "127.0.0.1",
    :http_port => 8098,
    :bucket => "_sessions",
    :r => 1,
    :w => 1,
    :dw => 0,
    :rw => 1,
    :n_val => 2,
    :last_write_wins => false,
    :content_type => "application/x-ruby-marshal"

    attr_reader :bucket

    # Creates a new Riak::SessionStore middleware
    # @param app the Rack application
    # @param [Hash] options configuration options
    # @see Rack::Session::Abstract::ID#initialize
    def initialize(app, options={})
      super
      @riak_options = options.merge(DEFAULT_OPTIONS)
      @client = Riak::Client.new(@default_options.slice(*Riak::Client::VALID_OPTIONS))
      @bucket = @client.bucket(default_options[:bucket])
      set_bucket_defaults
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
      if session_id && robject = (bucket.get(session_id) rescue nil)
        @session_id = session_id
        if stale?(robject)
          bucket.delete(session_id)
          fresh_session
        else
          [session_id, robject.data]
        end
      else
        fresh_session
      end
    end

    def set_session(env, session_id, session, options)
      if options[:renew] or options[:drop]
        bucket.delete(session_id)
        return false if options[:drop]
        session_id = generate_sid
      elsif session_id.nil?
        # Rails 2.3 kills the session id from the request when
        # reset_session is called. Working around that by temp.
        # storing it in the middleware and explicitly destroying it
        # as it's not guaranteed that Riak expiry is enabled
        session_id = if @session_id
                       destroy_session(env, @session_id, options)
                     else
                       generate_sid
                     end
      end

      robject = bucket.get_or_new(session_id)
      robject.content_type = options[:content_type]
      robject.meta['expire-after'] = (Time.now + options[:expire_after]).httpdate if options[:expire_after]
      robject.data = session
      robject.store
      session_id
    rescue Riak::FailedRequest
      env['rack.errors'].puts $!.inspect
      false
    end

    def destroy_session(env, sid, options)
      bucket.delete(sid)
      generate_sid unless options[:drop]
    end

    def stale?(robject)
      if robject.meta['expire-after'] && threshold = (Time.httpdate(robject.meta['expire-after'].first) rescue nil)
        threshold < Time.now
      else
        false
      end
    end

    def fresh_session
      session_id, robject = generate_sid, bucket.new
      robject.key = session_id
      robject.content_type = @riak_options[:content_type]
      robject.data = {}
      robject.store
      [session_id, robject.data]
    end

    private
    def set_bucket_defaults
      bucket_opts = @default_options.slice(:r,:w,:dw,:rw,:n_val,:last_write_wins).stringify_keys
      new_props = bucket_opts.inject({}) do |hash,(k,v)|
        hash[k] = v unless @bucket.props[k] == v
        hash
      end
      @bucket.props = new_props unless new_props.empty?
    end
  end
end
