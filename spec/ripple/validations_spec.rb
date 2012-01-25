require 'spec_helper'

describe Ripple::Validations do
  # require 'support/models/box'
  let(:klass) do
    class self.class::Valid
      include Ripple::Document
      self.bucket_name = "validators"
    end
    self.class::Valid
  end

  subject { klass.new }
  let(:client) { Ripple.client }
  after(:each) { self.class.send :remove_const, :Valid }
  before :each do
    client.stub(:store_object => true)
  end

  context "adding validation declarations to the class" do
    [:validates, :validate, :validates_with, :validates_each,
     :validates_acceptance_of, :validates_confirmation_of, :validates_exclusion_of,
     :validates_format_of, :validates_inclusion_of, :validates_length_of,
     :validates_numericality_of, :validates_presence_of].each do |meth|
      its(:class){ should respond_to(meth) }
    end
  end

  context "adding validation methods to the instance" do
    it { should respond_to(:errors) }
    it { should respond_to(:valid?) }
    it { should respond_to(:invalid?) }
  end

  it "should override save to run validations" do
    subject.should_receive(:valid?).and_return(false)
    subject.save.should be_false
  end

  it "should allow skipping validations by passing save :validate => false" do
    subject.should_not_receive(:valid?)
    subject.save(:validate => false).should be_true
  end

  describe "when using save! on an invalid record" do
    before(:each) { subject.stub!(:valid?).and_return(false) }

    it "should raise an exception that has the invalid document" do
      begin
        subject.save!
      rescue Ripple::DocumentInvalid => invalid
        invalid.document.should == subject
      else
        fail "Nothing was raised!"
      end
    end
  end

  it "should return true from save! when no exception is raised" do
    subject.stub!(:save).and_return(true)
    subject.stub!(:valid?).and_return(true)
    subject.save!.should be_true
  end

  it "should allow unexpected exceptions to be raised" do
    robject = mock("robject", :key => subject.key, "data=" => true, "content_type=" => true, "indexes=" => true)
    robject.should_receive(:store).and_raise(Riak::HTTPFailedRequest.new(:post, 200, 404, {}, "404 not found"))
    subject.stub!(:robject).and_return(robject)
    subject.stub!(:valid?).and_return(true)
    lambda { subject.save! }.should raise_error(Riak::FailedRequest)
  end

  it "should not raise an error when creating a box with create! succeeds" do
    subject.stub!(:new?).and_return(false)
    klass.stub(:create).and_return(subject)
    new_subject = nil
    new_subject = klass.create!
    new_subject.should == subject
  end

  it "should raise an error when creating a box with create! fails" do
    subject.stub!(:new?).and_return(true)
    klass.stub(:create).and_return(subject)
    lambda { klass.create! }.should raise_error(Ripple::DocumentInvalid)
  end


  it "should automatically add validations from property options" do
    klass.property :size, Integer, :inclusion => {:in => 1..30 }

    subject.size = 0
    subject.should be_invalid
  end

  it "should run validations at the correct lifecycle state" do
    klass.property :size, Integer, :inclusion => {:in => 1..30, :on => :update }

    subject.stub!(:new?).and_return(true)
    subject.size = 0
    subject.should be_valid
  end
end
