require 'spec_helper'

describe Ripple::Serialization do
  # require 'support/models/invoice'
  # require 'support/models/note'
  # require 'support/models/customer'

  it "should provide JSON serialization" do
    Invoice.new.should respond_to(:to_json)
  end

  context "when serializing" do
    it "should include attributes" do
      Note.new(:text => "Dear Jane,...").serializable_hash.should include('text')
    end

    it "should include the document key" do
      doc = Invoice.new
      doc.key = "1"
      doc.serializable_hash['key'].should == "1"
    end

    it "should be able to exclude the document key" do
      doc = Invoice.new
      doc.key = "1"
      doc.serializable_hash(:except => [:key]).should_not include("key")
    end

    it "should include embedded documents by default" do
      doc = Invoice.new(:note => {:text => "Dear customer,..."}).serializable_hash
      doc['note'].should eql({'text' => "Dear customer,..."})
    end

    it "should exclude the _type field from embedded documents" do
      doc = Invoice.new
      doc.note = Note.new :text => "Dear customer,..."
      doc.serializable_hash['note'].should_not include("_type")
    end

    it "should exclude specified attributes" do
      hash = Invoice.new.serializable_hash(:except => [:created_at])
      hash.should_not include('created_at')
    end

    it "should limit to specified attributes" do
      hash = Invoice.new.serializable_hash(:only => [:created_at])
      hash.should include('created_at')
      hash.should_not include('updated_at')
    end
  end
end
