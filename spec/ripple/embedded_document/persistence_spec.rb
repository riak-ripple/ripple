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
  class User;    include Ripple::Document; one :address; end
  class Address; include Ripple::EmbeddedDocument; end
  
  before :each do
    @root = mock("root document")
    @root.stub!(:new?).and_return(true)
    @root.stub!(:_root_document).and_return(@root)
    @addr = Address.new
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
    @root.should_receive(:save!).and_return(true)
    @addr.save!.should be_true
  end

  it "should have a root document" do
    @addr._root_document.should == @root
  end
  
  it "should have a parent document" do
     @addr._parent_document.should == @root
  end
  
  it "should properly create embedded attributes for persistence" do
    @user = User.new
    @addr = Address.new
    @user.address = @addr
    @user.attributes_for_persistence.should == {'_type' => 'User', 'address' => {'_type' => 'Address'}}
  end
end
