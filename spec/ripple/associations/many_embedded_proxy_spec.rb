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

describe Ripple::Document::Associations::ManyEmbeddedProxy do
  before :all do
    Object.module_eval do
      class User
        include Ripple::Document
        many :addresses
      end
      
      class Address
        include Ripple::EmbeddedDocument
        property :street, String, :presence => true
        many :notes
      end
      
      class Note; include Ripple::EmbeddedDocument; end
    end
  end
  
  before :each do
    @user    = User.new
    @address = Address.new
    @note    = Note.new
  end
  
  it "should not have children before any are set"
  
  it "should be able to set and get its children"
  
  it "should set the parent document on the children when assigning"
  
  it "should return the assignment when assigning"
  
  it "should set the parent document on the children when accessing"
  
  it "should be able to replace its children with different children"
  
  it "should be able to add to its children"
  
  it "should be able to count its children"
  
  it "should be able to find a child by its key"
  
  it "should be able to build a new child"
  
  it "should be able to create a new child"
  
  it "should be able to create! a new child"
  
  it "should assign a parent to the children created with instantiate_target"
  
  it "should validate the children when saving the parent"
  
  it "should allow embedding documents in embedded documents"
  
  after :all do
    Object.send(:remove_const, :User)
    Object.send(:remove_const, :Address)
    Object.send(:remove_const, :Note)
  end
end