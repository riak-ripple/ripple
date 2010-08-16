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
require File.expand_path("../../../spec_helper", __FILE__)

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
