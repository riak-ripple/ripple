require 'spec_helper'

describe Ripple::EmbeddedDocument::Persistence do
  require 'support/models/user'
  require 'support/models/address'
  
  before :each do
    @root = User.new
    @addr = Address.new(:street => "196 Broadway")
    @addr._parent_document = @root
  end

  it "should delegate new? to the root document" do
    @root.should_receive(:new?).and_return(true)
    @addr.should be_new
  end

  it "should delegate save to the root document" do
    @root.should_receive(:save).and_return(true)
    @addr.save.should be_true
  end
  
  it "should delegate save! to the root document" do
    @root.should_receive(:save).and_return(true)
    @addr.save!.should be_true
  end
  
  it "should raise NoRootDocument when calling save without a root document" do
    @addr._parent_document = nil
    lambda { @addr.save }.should raise_error(Ripple::NoRootDocument)
  end
  
  it "should raise NoRootDocument when calling save! without a root document" do
    @addr._parent_document = nil
    lambda { @addr.save! }.should raise_error(Ripple::NoRootDocument)
  end

  it "should have a root document" do
    @addr._root_document.should == @root
  end
  
  it "should have a parent document" do
     @addr._parent_document.should == @root
  end
  
  it "should respond to new_record?" do
    @addr.should respond_to(:new_record?)
    @addr.should be_a_new_record
  end
  
  it "should respond to persisted" do
    @addr.should respond_to(:persisted?)
    @addr.should_not be_persisted
  end
  
  it "should properly create embedded attributes for persistence" do
    @addr = Address.new
    @root.addresses << @addr
    @root.attributes_for_persistence.should == {'_type' => 'User', 'addresses' => [{'_type' => 'Address', 'street' => nil}]}
  end

  it "includes undefined properties in the attributes for persistence" do
    addr = Address.new
    addr['some_undefined_prop'] = 17
    @root.addresses << addr
    @root.attributes_for_persistence['addresses'].first.should include('some_undefined_prop' => 17)
  end

  it "should modify its attributes and save" do
    @addr.should_receive(:save).and_return(true)
    @addr.update_attributes(:street => "4 Folsom Ave")
    @addr.street.should == "4 Folsom Ave"
  end

  it "should update a single attribute and save without validations" do
    @addr.should_receive(:save).with(:validate => false).and_return(true)
    @addr.update_attribute(:street, "4 Folsom Ave")
    @addr.street.should == "4 Folsom Ave"
  end
end
