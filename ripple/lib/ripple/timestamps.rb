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
  # Adds automatic creation and update timestamps to a
  # {Ripple::Document} model.
  module Timestamps
    extend ActiveSupport::Concern

    module ClassMethods
      # Adds the :created_at and :updated_at timestamp properties to
      # the document.
      def timestamps!
        property :created_at, Time, :default => proc { Time.now }
        property :updated_at, Time
        before_save :touch
      end
    end

    module InstanceMethods
      # Sets the :updated_at attribute before saving the document.
      def touch
        self.updated_at = Time.now
      end
    end
  end
end
