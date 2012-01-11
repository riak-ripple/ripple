require 'spec_helper'

describe Ripple::EmbeddedDocument::Finders do
  # require 'support/models/address'
  # require 'support/models/favorite'

  before :each do
    @address = Address.new
  end

  it "should instantiate a document" do
    Address.stub!(:new).and_return(@address)
    Address.instantiate('_type' => 'Address').should == @address
  end

  it "should instantiate a class of _type if present in attrs" do
    Favorite.instantiate('_type' => 'Address').class.should == Address
  end

  it "should use self if being called from a class including Ripple::EmbeddedDocument and _type is not present" do
    Address.instantiate({}).class.should == Address
  end

  it 'initializes the document with no changes' do
    a = Address.instantiate('_type' => 'Address', 'street' => 'Pine St')
    a.should_not be_changed
    a.changes.should be_empty
  end
end
