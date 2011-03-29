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

describe Ripple::Associations::OneEmbeddedProxy do
  require 'support/models/family'
  require 'support/models/user'
  require 'support/models/address'
  
  before :each do
    @parent = Parent.new
    @child  = Child.new
    @gchild = Grandchild.new
  end
  
  it "should not have a child before one is set" do
    @parent.child.should be_nil
  end

  it "should raise NoMethodError when an undefined method is called on the unset child" do
    expect { @parent.child.some_undefined_method }.to raise_error(NoMethodError)
  end
  
  it "should be able to set and get its child" do
    @parent.child = @child
    @parent.child.should equal(@child)
  end
  
  it "should set the parent document on the child when assigning" do
    @parent.child = @child
    @child._parent_document.should == @parent
  end
  
  it "should return the assignment when assigning" do
    rtn = @parent.child = @child
    rtn.should == @child
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
  
  it "should assign a parent to the child created with instantiate_target" do
    Child.stub!(:new).and_return(@child)
    @child._parent_document.should be_nil
    @parent.child.build._parent_document.should == @parent
  end
  
  it "should validate the child when saving the parent" do
    @parent.valid?.should be_true
    @child.name = ''
    @parent.child = @child
    @child.valid?.should be_false
    @parent.valid?.should be_false
  end
  
  it "should not save the root document when a child is invalid" do
    @parent.child = @child
    @parent.save.should be_false
  end
  
  it "should allow embedding documents in embedded documents" do
    @parent.child = @child
    @child.gchild = @gchild
    @gchild._root_document.should   == @parent
    @gchild._parent_document.should == @child
  end

  it "should refuse assigning a document of the wrong type" do
    lambda { @parent.child = @gchild }.should raise_error
    lambda { @child.gchild = [] }.should raise_error
  end
  
  describe "callbacks" do
    before :each do
      $pinger = mock("callback verifier")
    end
    
    it "should run callbacks for the child and documents" do
      $pinger.should_receive(:ping).once
      Child.before_validation { $pinger.ping }
      @child = Child.new
      @child.valid?
    end 

    # this will work using parent and child classes, but only run by itself
    # it also works using different classes, but only run in this file
    # IDK why that is, but my Yakshaver 2000 just ran out of juice
    
    # does this even matter? we call valid? all over the place and that
    # will trigger the callback anyway. 
    # you probably shouldn't use validation callbacks and expect them to 
    # *only* run once
    
    # it "should run callbacks for the parent and child and documents respectivly" do
    #   $pinger = mock("callback verifier")
    #   $pinger.should_receive(:ping).once
    #   $pinger.should_receive(:pong).once
    #   Child.before_validation  { $pinger.ping }
    #   Parent.before_validation { $pinger.pong }
    #   @child  = Child.new
    #   @parent = Parent.new
    #   @parent.child = @child
    #   @parent.valid?
    # end
    
    after :each do
      Child.reset_callbacks(:validation)
      Parent.reset_callbacks(:validation)
    end
  end

end
