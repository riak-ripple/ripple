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
require File.expand_path("../../spec_helper", __FILE__)

describe Ripple::Document::AttributeMethods do
  before :all do
    Object.module_eval do
      class Widget
        include Ripple::Document
        property :size, Integer
        property :name, String, :default => "widget"
      end
    end
  end

  before :each do
    @widget = Widget.new
  end

  describe "object key" do
    it "should provide access to the key" do
      @widget.should respond_to(:key)
      @widget.key.should be_nil
    end

    it "should provide a mutator for the key" do
      @widget.should respond_to(:key=)
      @widget.key = "cog"
      @widget.key.should == "cog"
    end

    it "should accept the key in mass assignment" do
      @widget.attributes = {:key => "cog"}
      @widget.key.should == "cog"
    end

  end

  describe "accessors" do
    it "should be defined for defined properties" do
      @widget.should respond_to(:size)
      @widget.should respond_to(:name)
    end

    it "should return nil if no default is defined on the property" do
      @widget.size.should be_nil
    end

    it "should return the property default if defined and not set" do
      @widget.name.should == "widget"
    end

    it "should expose the property directly" do
      @widget.name.gsub!("w","f")
      @widget.name.should == "fidget"
    end
  end

  describe "mutators" do
    it "should have mutators for defined properties" do
      @widget.should respond_to(:size=)
      @widget.should respond_to(:name=)
    end

    it "should assign the value of the attribute" do
      @widget.size = 10
      @widget.size.should == 10
    end

    it "should type cast assigned values automatically" do
      @widget.name = :so_what
      @widget.name.should == "so_what"
    end

    it "should raise an error when assigning a bad value" do
      lambda { @widget.size = true }.should raise_error(Ripple::PropertyTypeMismatch)
    end
  end

  describe "query methods" do
    it "should be defined for defined properties" do
      @widget.should respond_to(:size?)
      @widget.should respond_to(:name?)
    end

    it "should be false when the attribute is nil" do
      @widget.size.should be_nil
      @widget.size?.should be_false
    end

    it "should be true when the attribute has a value present" do
      @widget.size = 10
      @widget.size?.should be_true
    end

    it "should be false for 0 values" do
      @widget.size = 0
      @widget.size?.should be_false
    end

    it "should be false for empty values" do
      @widget.name = ""
      @widget.name?.should be_false
    end
  end

  it "should track changes to attributes" do
    @widget.name = "foobar"
    @widget.changed?.should be_true
    @widget.name_changed?.should be_true
    @widget.name_change.should == ["widget", "foobar"]
    @widget.changes.should == {"name" => ["widget", "foobar"]}
  end


  it "should refresh the attribute methods when adding a new property" do
    Widget.should_receive(:undefine_attribute_methods)
    Widget.property :start_date, Date
    Widget.properties.delete(:start_date) # cleanup
  end

  it "should provide a hash representation of all of the attributes" do
    @widget.attributes.should == {"name" => "widget", "size" => nil}
  end

  it "should load attributes from mass assignment" do
    @widget.attributes = {"name" => "Riak", "size" => 100000 }
    @widget.name.should == "Riak"
    @widget.size.should == 100000
  end

  it "should assign attributes on initialization" do
    @widget = Widget.new(:name => "Riak")
    @widget.name.should == "Riak"
  end

  it "should have no changed attributes after initialization" do
    @widget = Widget.new(:name => "Riak")
    @widget.changes.should be_blank
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
end
