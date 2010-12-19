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
require 'ripple'

module Ripple
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      # @private
      def save(*args)
        if result = super
          changed_attributes.clear
        end
        result
      end

      # @private
      def reload
        super.tap do
          changed_attributes.clear
        end
      end

      # @private
      def initialize(attrs={})
        super(attrs)
        changed_attributes.clear
      end

      private
      def attribute=(attr_name, value)
        attribute_will_change!(attr_name) if @attributes[attr_name] != value
        super
      end
    end
  end
end
