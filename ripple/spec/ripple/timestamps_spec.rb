require 'spec_helper'

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
    record_to_save.save
    subject.updated_at.should_not be_nil
  end

  it "updates the updated_at timestamp when the object is updated" do
    record_to_save.save
    start = subject.updated_at
    record_to_save.save
    subject.updated_at.should > start
  end

  it "does not update the created_at timestamp when the object is updated" do
    record_to_save.save
    start = subject.created_at
    record_to_save.save
    subject.created_at.should == start
  end
end

describe Ripple::Timestamps do
  # require 'support/models/clock'

  before(:each) { clock.robject.stub!(:store).and_return(true) }

  context "for a Ripple::Document" do
    it_behaves_like "a timestamped model" do
      subject { Clock.new }
      let(:clock) { subject }
      let(:record_to_save) { subject }      
    end
  end

  context "for a Ripple::EmbeddedDocument when directly saved" do
    it_behaves_like "a timestamped model" do
      let(:clock) { Clock.new }
      subject { Mode.new }
      let(:record_to_save) { subject }

      before(:each) do
        clock.modes << subject
      end
    end
  end

  context "for a Ripple::EmbeddedDocument when the parent is saved" do
    it_behaves_like "a timestamped model" do
      let(:clock) { Clock.new }
      subject { Mode.new }
      let(:record_to_save) { clock }
      
      before(:each) do
        clock.modes << subject
      end

      it "should pass-through property options to the created properties" do
        [:created_at, :updated_at].each do |p|
          subject.class.properties[p].validation_options.should include(:presence)
          subject.class.indexes[p].should be
        end
      end
    end
  end
end
