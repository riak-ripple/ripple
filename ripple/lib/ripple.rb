require 'riak'
require 'erb'
require 'yaml'
require 'active_model'
require 'ripple/core_ext'
require 'ripple/translation'
require 'ripple/document'
require 'ripple/embedded_document'

# Contains the classes and modules related to the ODM built on top of
# the basic Riak client.
module Ripple
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
      configure_ports(config_hash)
      self.config = config_hash || {}
    rescue Errno::ENOENT
      raise Ripple::MissingConfiguration.new(config_file)
    end
    alias_method :load_config, :load_configuration

    private
    def client_config
      config.slice(*Riak::Client::VALID_OPTIONS)
    end

    def configure_ports(config)
      return unless config && config[:min_port]
      config[:http_port] ||= (config[:min_port].to_i)
      config[:pb_port] ||= (config[:min_port].to_i + 1)
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
