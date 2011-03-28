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
begin
  require 'action_dispatch/middleware/session/abstract_store'
rescue LoadError, NameError
  # TODO i18n this message
  $stderr.puts "Ripple::SessionStore requires ActionPack >= 3.0.0"
  exit 1
end

module Ripple
  # A Rails 3-compatible, Riak-backed session store.
  class SessionStore < ActionDispatch::Session::AbstractStore
    def initialize(app, options={})
      super
      @default_options = {
        :bucket => "_sessions",
        :r => 1,
        :w => 1,
        :dw => 0,
        :rw => 1,
        :n_val => 2,
        :last_write_wins => false,
        :host => "127.0.0.1",
        :port => 8098
      }.merge(@default_options)
      @client = Riak::Client.new(@default_options.slice(:host,:port,:client_id))
      @bucket = @client.bucket(@default_options[:bucket])
      set_bucket_defaults
    end

    private
    def get_session(env, sid)
      sid ||= generate_sid
      session = {}
      begin
        session = @bucket.get(sid).data
      rescue Riak::FailedRequest => fr
        raise fr unless fr.not_found?
      end
      [sid, session]
    end

    def set_session(env, sid, session_data)
      robject = @bucket.get_or_new(sid)
      robject.content_type = "application/x-ruby-marshal"
      robject.data = session_data
      robject.store
      sid
    rescue Riak::FailedRequest
      false
    end

    def destroy(env)
      if sid = current_session_id(env)
        @bucket.delete(sid)
      end
    rescue Riak::FailedRequest
      false
    end

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
