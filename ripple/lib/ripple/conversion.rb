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
  # Provides ActionPack compatibility for {Ripple::Document} models.
  module Conversion
    include ActiveModel::Conversion

    # True if this is a new document
    def new_record?
      new?
    end

    # True if this is not a new document
    def persisted?
      !new?
    end

    # Converts to a view key
    def to_key
      new? ? nil : [key]
    end

    # Converts to a URL parameter
    def to_param
      key
    end
  end
end
