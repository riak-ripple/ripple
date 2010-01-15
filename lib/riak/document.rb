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
require 'riak'

module Riak
  # Represents hash-like documents (JSON, YAML). Documents will be automatically
  # serialized into the appropriate format when sent in requests and deserialized
  # from responses.
  class Document < RObject
    DOCUMENT_TYPES = [ /json$/i, /yaml$/i ].freeze

    def self.matches?(headers)
      DOCUMENT_TYPES.any? { |type| headers["content-type"].first =~ type }
    end

    def serialize(data)
      case @content_type
      when /json$/i
        data.to_json
      when /yaml$/i
        YAML.dump(data)
      else
        data
      end
    end

    def deserialize(data)
      case @content_type
      when /json$/i
        JSON.parse(data)
      when /yaml$/i
        YAML.load(data)
      else
        data
      end
    end
  end
end
