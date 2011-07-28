require 'spec_helper'

describe Ripple::Inspection do
  require 'support/models/box'
  require 'support/models/address'

  shared_examples_for 'an inspected document' do |method|

    it "should include the class name in the inspect string" do
      @box.send(method).should be_starts_with("<Box")
    end

    it "should include the key in the #{method} string for documents" do
      @box.key = "square"
      @box.send(method).should be_starts_with("<Box:square")
    end

    it "should indicate a new document when no key is specified" do
      @box.send(method).should be_starts_with("<Box:[new]")
    end

    it "should not display a key for embedded documents" do
      @address.send(method).should_not include("[new]")
    end

  end

  before :each do
    @box = Box.new
    @address = Address.new
  end

  describe '#inspect' do

    it_should_behave_like 'an inspected document', :inspect

    it "should enumerate the document's properties and their values" do
      @box.shape = "square"
      @box.inspect.should include("shape=\"square\"")
      @box.inspect.should include("created_at=")
      @box.inspect.should include("updated_at=")
    end

  end

  describe '#to_s' do

    it_should_behave_like 'an inspected document', :to_s

  end
end
