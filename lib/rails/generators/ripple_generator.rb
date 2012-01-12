require 'rails/generators'
require "rails/generators/named_base"
require "rails/generators/active_model"

class RippleGenerator < ::Rails::Generators::Base
  def create_ripple
    invoke "ripple:configuration"
    invoke "ripple:js"
    invoke "ripple:test"
  end
end

module Ripple
  # ActiveModel generators for use in a Rails project.
  module Generators
    # @private
    class Base < ::Rails::Generators::Base
      def self.source_root
        @_ripple_source_root ||=
        File.expand_path("../#{base_name}/#{generator_name}/templates", __FILE__)
      end
    end

    class NamedBase < ::Rails::Generators::NamedBase
      def self.source_root
        @_ripple_source_root ||=
        File.expand_path("../#{base_name}/#{generator_name}/templates", __FILE__)
      end
    end

    # Generator for a {Ripple::Document} model
    class ActiveModel < ::Rails::Generators::ActiveModel
      def self.all(klass)
        "#{klass}.list"
      end

      def self.find(klass, params=nil)
        "#{klass}.find(#{params})"
      end

      def self.build(klass, params=nil)
        if params
          "#{klass}.new(#{params})"
        else
          "#{klass}.new"
        end
      end

      def save
        "#{name}.save"
      end

      def update_attributes(params=nil)
        "#{name}.update_attributes(#{params})"
      end

      def errors
        "#{name}.errors"
      end

      def destroy
        "#{name}.destroy"
      end
    end
  end
end

# @private
module Rails
  module Generators
    class GeneratedAttribute #:nodoc:
      def type_class
        return "Time" if type.to_s == "datetime"
        return "String" if type.to_s == "text"
        return type.to_s.camelcase
      end
    end
  end
end
