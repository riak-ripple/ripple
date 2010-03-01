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
  module EmbeddedDocument
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :Persistence
    include Translation

    included do
      extend ActiveModel::Naming
      extend Ripple::Document::Properties
      include Persistence
      include Ripple::Document::AttributeMethods
      include Ripple::Document::Timestamps
      include Ripple::Document::Validations
    end

    module ClassMethods
      def embeddable?
        !included_modules.include?(Document)
      end
    end
  end
end
