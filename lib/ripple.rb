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
require 'active_support/all'
require 'active_model'
require 'ripple/i18n'

# Contains the classes and modules related to the ODM built on top of
# the basic Riak client.
module Ripple
  extend ActiveSupport::Autoload
  include ActiveSupport::Configurable

  autoload :EmbeddedDocument
  autoload :Document
  autoload :PropertyTypeMismatch
  autoload :Translation

  DEFAULT_CONFIG = {}

  class << self
    # @return [Riak::Client] The client for the current thread.
    def client
      Thread.current[:ripple_client] ||= Riak::Client.new(config)
    end

    # Sets the client for the current thread.
    # @param [Riak::Client] value the client
    def client=(value)
      Thread.current[:ripple_client] = value
    end

    def config=(value)
      self.client = nil
      super
    end
  end
end
