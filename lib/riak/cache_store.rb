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
  class CacheStore < ActiveSupport::Cache::Store
    attr_accessor :client

    def initialize(options = {})
      @bucket_name = options.delete(:bucket) || '_cache'
      @n_value = options.delete(:n_value) || 2
      @r = [options.delete(:r) || 1, @n_value].min
      @w = [options.delete(:w) || 1, @n_value].min
      @dw = [options.delete(:dw) || 0, @n_value].min
      @rw = [options.delete(:rw) || 1, @n_value].min
      @client = Riak::Client.new(options)
    end

    def bucket
      @bucket ||= @client.bucket(@bucket_name, :keys => false).tap do |b|
        begin
          b.n_value = @n_value unless b.n_value == @n_value
        rescue
        end
      end
    end
    
    def write(key, value, options={})
      super do
        object = bucket.get_or_new(key, :r => @r)
        object.content_type = 'application/yaml'
        object.data = value
        object.store(:r => @r, :w => @w, :dw => @dw)
      end
    end

    def read(key, options={})
      super do
        begin
          bucket.get(key, :r => @r).data
        rescue Riak::FailedRequest => fr
          raise fr unless fr.code == 404
          nil
        end
      end
    end

    def exist?(key)
      super do
        bucket.exists?(key, :r => @r)
      end
    end

    def delete_matched(matcher, options={})
      super do
        bucket.keys do |keys|
          keys.grep(matcher).each do |k|
            bucket.delete(k, :rw => @rw)
          end
        end
      end
    end

    def delete(key, options={})
      super do
        bucket.delete(key, :rw => @rw)
      end
    end
  end
end

ActiveSupport::Cache::RiakStore = Riak::CacheStore unless defined?(ActiveSupport::Cache::RiakStore)
