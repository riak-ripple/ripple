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
  # Represents a model stored in Riak, serialized in JSON object (document).
  # Ripple::Document models aim to be fully ActiveModel compatible, with a keen
  # eye toward features that developers expect from ActiveRecord, DataMapper and MongoMapper.
  #
  # Example:
  #
  #   class Email
  #     include Ripple::Document
  #     property :from,    String, :presence => true
  #     property :to,      String, :presence => true
  #     property :sent,    Time,   :default => proc { Time.now }
  #     property :body,    String
  #   end
  #
  #   email = Email.find("37458abc752f8413e")  # GET /riak/emails/37458abc752f8413e
  #   email.from = "someone@nowhere.net"
  #   email.save                               # PUT /riak/emails/37458abc752f8413e
  #
  #   reply = Email.new
  #   reply.from = "justin@bashoooo.com"
  #   reply.to   = "sean@geeemail.com"
  #   reply.body = "Riak is a good fit for scalable Ruby apps."
  #   reply.save                               # POST /riak/emails (Riak-assigned key)
  #
  module Document
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :BucketAccess
    autoload :Finders
    autoload :Key
    autoload :Persistence

    included do
      extend ActiveModel::Naming
      extend BucketAccess
      include Ripple::Document::Key
      include Ripple::Document::Persistence
      extend Ripple::Properties
      include Ripple::AttributeMethods
      include Ripple::Timestamps
      include Ripple::Validations
      include Ripple::Associations
      include Ripple::Callbacks
      include Ripple::Observable
      include Ripple::Conversion
      include Ripple::Document::Finders
      include Ripple::Inspection
      include Ripple::NestedAttributes
      include Ripple::Serialization
    end

    module ClassMethods
      def embeddable?
        false
      end
    end

    module InstanceMethods
      def _root_document
        self
      end

      # Returns true if the +comparison_object+ is the same object, or is of the same type and has the same key.
      def ==(comparison_object)
        comparison_object.equal?(self) ||
          (comparison_object.class < Document && (comparison_object.instance_of?(self.class) || comparison_object.class.bucket.name == self.class.bucket.name) &&
           comparison_object.key == key && !comparison_object.new?)
      end
    end
  end
end
