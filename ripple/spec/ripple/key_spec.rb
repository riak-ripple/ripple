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
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Ripple::Document::Key do
  require 'support/models/box'
  before do
    @box = Box.new
  end
  
  it "should define key getter and setter" do
    @box.should respond_to(:key)
    @box.should respond_to(:key=)
  end

  it "should stringify the assigned key" do
    @box.key = 2
    @box.key.should == "2"
  end

  it "should use a property as the key" do
    class ShapedBox < Box
      key_on :shape
    end
    @box = ShapedBox.new
    @box.key = "square"
    @box.key.should == "square"
    @box.shape.should == "square"
    @box.shape = "oblong"
    @box.key.should == "oblong"
  end  
end
