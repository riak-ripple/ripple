require 'spec_helper'

describe Ripple::Associations::ManyEmbeddedProxy do
  # require 'support/models/user'
  # require 'support/models/address'
  # require 'support/models/note'

  before :each do
    @user    = User.new(:email => "riak@ripple.com")
    @address = Address.new
    @addr    = Address.new(:street => '123 Somewhere')
    @note    = Note.new
  end

  it "should not have children before any are set" do
    @user.addresses.should == []
  end

  it "should be able to set and get its children" do
    Address.stub!(:instantiate).and_return(@address)
    @user.addresses = [@address]
    @user.addresses.should == [@address]
  end

  it "should set the parent document on the children when assigning" do
    @user.addresses = [@address]
    @address._parent_document.should == @user
  end

  it "should return the assignment when assigning" do
    rtn = @user.addresses = [@address]
    rtn.should == [@address]
  end

  it "should set the parent document on the children when accessing" do
    @user.addresses = [@address]
    @user.addresses.first._parent_document.should == @user
  end

  it "should be able to replace its children with different children" do
    @user.addresses = [@address]
    @user.addresses.first.street.should be_blank
    @user.addresses = [@addr]
    @user.addresses.first.street.should == '123 Somewhere'
  end

  it "should be able to add to its children" do
    Address.stub!(:instantiate).and_return(@address)
    @user.addresses = [@address]
    @user.addresses << @address
    @user.addresses.should == [@address, @address]
  end

  it "should be able to chain calls to adding children" do
    Address.stub!(:instantiate).and_return(@address)
    @user.addresses = [@address]
    @user.addresses << @address << @address << @address
    @user.addresses.should == [@address, @address, @address, @address]
  end

  it "should set the parent document when adding to its children" do
    @user.addresses << @address
    @user.addresses.first._parent_document.should == @user
  end

  it "should be able to count its children" do
    @user.addresses = [@address, @address]
    @user.addresses.count.should == 2
  end

  it "should be able to build a new child" do
    Address.stub!(:new).and_return(@address)
    @user.addresses.build.should == @address
  end

  it "should assign a parent to the children created with instantiate_target" do
    Address.stub!(:new).and_return(@address)
    @address._parent_document.should be_nil
    @user.addresses.build._parent_document.should == @user
  end

  it "should validate the children when saving the parent" do
    @user.valid?.should be_true
    @user.addresses << @address
    @address.valid?.should be_false
    @user.valid?.should be_false
  end

  it "should not save the root document when a child is invalid" do
    @user.addresses << @address
    @user.save.should be_false
  end

  it "should allow embedding documents in embedded documents" do
    @user.addresses << @address
    @address.notes << @note
    @note._root_document.should   == @user
    @note._parent_document.should == @address
  end

  it "should allow assiging child documents as an array of hashes" do
    @user.attributes = {'addresses' => [{'street' => '123 Somewhere'}]}
    @user.addresses.first.street.should == '123 Somewhere'
  end

  it "should return an array from to_ary" do
    Address.stub!(:instantiate).and_return(@address)
    @user.addresses << @address
    @user.addresses.to_ary.should == [@address]
  end

  it "should refuse assigning documents of the wrong type" do
    lambda { @user.addresses = nil }.should raise_error
    lambda { @user.addresses = @address }.should raise_error
    lambda { @user.addresses = [@note] }.should raise_error
  end

  it "should not add the associated validator multiple times" do
    User.validators_on(:addresses).count.should eq(1)
  end
end
