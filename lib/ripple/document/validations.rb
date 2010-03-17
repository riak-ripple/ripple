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
  module Document
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Validations
      
      included do
        alias_method_chain :save, :validation
      end

      module ClassMethods
        # @private
        def property(key, type, options={})
          prop = super
          validates key, prop.validation_options unless prop.validation_options.blank?
        end
      end

      module InstanceMethods
        # @private
        def save_with_validation(options={})
          return false if options[:validate] && !valid?
          save_without_validation
        end
        
        # @private
        def valid?
          @_on_validate = new? ? :create : :update
          super
        end
      end
    end
  end
end
