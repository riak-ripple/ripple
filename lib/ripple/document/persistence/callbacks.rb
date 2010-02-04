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
    module Persistence
      module Callbacks
        extend ActiveSupport::Concern

        included do
          extend ActiveModel::Callbacks
          define_model_callbacks :create, :update, :save, :destroy
        end

        module InstanceMethods
          # @private
          def save
            state = new? ? :create : :update
            run_callbacks(:save) do
              run_callbacks(state) do
                super
              end
            end
          end

          # @private
          def destroy
            run_callbacks(:destroy) do
              super
            end
          end
        end
      end
    end
  end
end
