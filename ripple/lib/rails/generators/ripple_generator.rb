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
        "#{klass}.all"
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
