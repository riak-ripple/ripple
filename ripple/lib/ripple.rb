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
require 'active_support/json'
require 'active_model'
require 'ripple/i18n'
require 'ripple/core_ext'
require 'ripple/translation'

# Contains the classes and modules related to the ODM built on top of
# the basic Riak client.
module Ripple
  extend ActiveSupport::Autoload

  # Primary models
  autoload :EmbeddedDocument
  autoload :Document

  # Model mixins and support classes
  autoload :Association, "ripple/associations"
  autoload :Associations
  autoload :AttributeMethods
  autoload :Callbacks
  autoload :Conversion
  autoload :Properties
  autoload :Property, "ripple/properties"
  autoload :Timestamps
  autoload :Validations
  autoload :NestedAttributes
  autoload :Observable
  autoload :Serialization

  # Exceptions
  autoload :PropertyTypeMismatch

  # Utilities
  autoload :Inspection

  class << self
    # @return [Riak::Client] The client for the current thread.
    def client
      Thread.current[:ripple_client] ||= Riak::Client.new(client_config)
    end

    # Sets the client for the current thread.
    # @param [Riak::Client] value the client
    def client=(value)
      Thread.current[:ripple_client] = value
    end

    # Sets the global Ripple configuration.
    def config=(hash)
      self.client = nil
      @config = hash.symbolize_keys
    end

    # Reads the global Ripple configuration.
    def config
      @config ||= {}
    end

    # The format in which date/time objects will be serialized to
    # strings in JSON.  Defaults to :iso8601, and can be set in
    # Ripple.config.
    # @return [Symbol] the date format
    def date_format
      (config[:date_format] ||= :iso8601).to_sym
    end

    # Sets the format for date/time objects that are serialized to
    # JSON.
    # @param [Symbol] format the date format
    def date_format=(format)
      config[:date_format] = format.to_sym
    end

    # Loads the Ripple configuration from a given YAML file.
    # Evaluates the configuration with ERB before loading.
    def load_configuration(config_file, config_keys = [:ripple])
      config_file = File.expand_path(config_file)
      config_hash = YAML.load(ERB.new(File.read(config_file)).result).with_indifferent_access
      config_keys.each {|k| config_hash = config_hash[k]}
      self.config = config_hash || {}
    rescue Errno::ENOENT
      raise Ripple::MissingConfiguration.new(config_file)
    end
    alias_method :load_config, :load_configuration

    private
    def client_config
      config.slice(*Riak::Client::VALID_OPTIONS)
    end
  end

  # Exception raised when the path passed to
  # {Ripple::load_configuration} does not point to a existing file.
  class MissingConfiguration < StandardError
    include Translation
    def initialize(file_path)
      super(t("missing_configuration", :file => file_path))
    end
  end
end

require 'ripple/railtie' if defined? Rails::Railtie
