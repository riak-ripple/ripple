require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for "a timestamped model" do
  it "adds a created_at property" do
    subject.should respond_to(:created_at)
  end

  it "adds an updated_at property" do
    subject.should respond_to(:updated_at)
  end

  it "sets the created_at timestamp when the object is initialized" do
    subject.created_at.should_not be_nil
  end

  it "does not set the updated_at timestamp when the object is initialized" do
    subject.updated_at.should be_nil
  end

  it "sets the updated_at timestamp when the object is saved" do
    subject.save
    subject.updated_at.should_not be_nil
  end

  it "updates the updated_at timestamp when the object is updated" do
    subject.save
    start = subject.updated_at
    subject.save
    subject.updated_at.should > start
  end

  it "does not update the created_at timestamp when the object is updated" do
    subject.save
    start = subject.created_at
    subject.save
    subject.created_at.should == start
  end
end

describe Ripple::Timestamps do
  require 'support/models/clock'

  let(:backend) { mock("Backend", :store_object => true) }
  before(:each) { Ripple.client.stub!(:backend).and_return(backend) }

  context "for a Ripple::Document" do
    subject { Clock.new }
    it_behaves_like "a timestamped model"
  end

  context "for a Ripple::EmbeddedDocument" do
    let(:clock) { Clock.new }

    subject do
      Mode.new.tap do |m|
        clock.modes << m
      end
    end

    it_behaves_like "a timestamped model"
  end
end
