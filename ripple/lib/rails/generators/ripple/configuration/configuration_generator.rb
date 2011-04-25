require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class ConfigurationGenerator < Base
      desc 'Generates a configuration file for Ripple.'

      def create_configuration_file
        template 'ripple.yml', 'config/ripple.yml'
      end
    end
  end
end
