require 'active_support/concern'
require 'active_model/naming'
require 'ripple/conflict/document_hooks'
require 'ripple/document/bucket_access'
require 'ripple/document/key'
require 'ripple/document/persistence'
require 'ripple/document/finders'
require 'ripple/document/link'
require 'ripple/properties'
require 'ripple/attribute_methods'
require 'ripple/indexes'
require 'ripple/timestamps'
require 'ripple/validations'
require 'ripple/associations'
require 'ripple/callbacks'
require 'ripple/observable'
require 'ripple/conversion'
require 'ripple/inspection'
require 'ripple/nested_attributes'
require 'ripple/serialization'

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

    included do
      extend ActiveModel::Naming
      extend BucketAccess
      include Ripple::Document::Key
      include Ripple::Document::Persistence
      extend Ripple::Properties
      include Ripple::Document::Finders
      include Ripple::AttributeMethods
      include Ripple::Timestamps
      include Ripple::Indexes
      include Ripple::Indexes::DocumentMethods
      include Ripple::Validations
      include Ripple::Associations
      include Ripple::Callbacks
      include Ripple::Observable
      include Ripple::Conversion
      include Ripple::Inspection
      include Ripple::NestedAttributes
      include Ripple::Serialization
      include Ripple::Conflict::DocumentHooks
    end

    module ClassMethods
      def embeddable?
        false
      end
    end

    def _root_document
      self
    end

    # Returns true if the +comparison_object+ is the same object, or is of the same type and has the same key.
    def ==(comparison_object)
      comparison_object.equal?(self) ||
        (comparison_object.class < Document && (comparison_object.instance_of?(self.class) || comparison_object.class.bucket.name == self.class.bucket.name) &&
         !new? && comparison_object.key == key && !comparison_object.new?)
    end

    def eql?(other)
      return true if other.equal?(self)

      (other.class.equal?(self.class)) &&
      !other.new? && !new? &&
      (other.key == key)
    end

    def hash
      if new?
        super # every new document should be treated as a different doc
      else
        [self.class, key].hash
      end
    end
  end
end
