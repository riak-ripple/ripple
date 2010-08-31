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

module Riak
  # An ActiveSupport::Cache::Store implementation that uses Riak.
  # Compatible only with ActiveSupport version 3 or greater.
  class CacheStore < ActiveSupport::Cache::Store
    attr_accessor :client

    # Creates a Riak-backed cache store.
    def initialize(options = {})
      super
      @bucket_name = options.delete(:bucket) || '_cache'
      @n_value = options.delete(:n_value) || 2
      @r = options.delete(:r) || 1
      @w = options.delete(:w) || 1
      @dw = options.delete(:dw) || 0
      @rw = options.delete(:rw) || "quorum"
      @client = Riak::Client.new(options)
      set_bucket_defaults
    end

    def bucket
      @bucket ||= @client.bucket(@bucket_name, :keys => false)
    end

    def delete_matched(matcher, options={})
      instrument(:delete_matched, matcher) do
        bucket.keys do |keys|
          keys.grep(matcher).each do |k|
            bucket.delete(k)
          end
        end
      end
    end

    protected
    def set_bucket_defaults
      begin
        new_values = {}
        new_values['n_val'] = @n_value unless bucket.n_value == @n_value
        new_values['r']     = @r       unless bucket.r == @r
        new_values['w']     = @w       unless bucket.w == @w
        new_values['dw']    = @dw      unless bucket.dw == @dw
        new_values['rw']    = @rw      unless bucket.rw == @rw
        bucket.props = new_values      unless new_values.empty?
      rescue
      end
    end

    def write_entry(key, value, options={})
      object = bucket.get_or_new(key)
      object.content_type = 'application/yaml'
      object.data = value
      object.store
    end

    def read_entry(key, options={})
      begin
        bucket.get(key).data
      rescue Riak::FailedRequest => fr
        raise fr unless fr.code == 404
        nil
      end
    end

    def delete_entry(key, options={})
      bucket.delete(key)
    end
  end
end

ActiveSupport::Cache::RiakStore = Riak::CacheStore unless defined?(ActiveSupport::Cache::RiakStore)
