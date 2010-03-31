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

describe Ripple::Document::Associations::OneEmbeddedProxy do
  before :all do
    Object.module_eval do
      class Parent
        include Ripple::Document
        one :child
      end
      
      class Child
        include Ripple::EmbeddedDocument
        property :name, String, :presence => true
        one :gchild, :class_name => 'Grandchild'
      end
      
      class Grandchild; include Ripple::EmbeddedDocument; end
    end
  end
  
  before :each do
    @parent = Parent.new
    @child  = Child.new
    @gchild = Grandchild.new
  end
  
  it "should not have a child before one is set" do
    @parent.child.should be_nil
  end
  
  it "should be able to set and get its child" do
    Child.stub!(:instantiate).and_return(@child)
    @parent.child = @child
    @parent.child.should == @child
  end
  
  it "should set the parent document on the child when assigning" do
    @parent.child = @child
    @child._parent_document.should == @parent
  end
  
  it "should set the parent document on the child when accessing" do
    @parent.child = @child
    @parent.child._parent_document.should == @parent
  end
  
  it "should be able to replace its child with a different child" do
    @son = Child.new(:name => 'Son')
    @parent.child = @child
    @parent.child.name.should be_blank
    @parent.child = @son
    @parent.child.name.should == 'Son'
  end
  
  it "should be able to build a new child" do
    Child.stub!(:new).and_return(@child)
    @parent.child.build.should == @child
  end
  
  it "should be able to create a new child" do
    Child.stub!(:create).and_return(@child)
    @parent.child.create.should == @child
  end
  
  it "should be able to create! a new child" do
    Child.stub!(:create!).and_return(@child)
    @parent.child.create!.should == @child
  end
  
  it "should assign a parent to the child created with instantiate_target" do
    Child.stub!(:new).and_return(@child)
    @parent.child.build._parent_document.should == @parent
  end
  
  it "should validate the child when saving the parent" do
    @parent.valid?.should be_true
    @child.name = ''
    @parent.child = @child
    @parent.valid?.should be_false
  end
  
  it "should allow embedding documents in embedded documents" do
    @parent.child = @child
    @child.gchild = @gchild
    @gchild._root_document.should   == @parent
    @gchild._parent_document.should == @child
  end
  
  after :all do
    Object.send(:remove_const, :Parent)
    Object.send(:remove_const, :Child)
    Object.send(:remove_const, :Grandchild)
  end
end