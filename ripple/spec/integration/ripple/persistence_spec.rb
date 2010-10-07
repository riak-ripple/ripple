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

describe "Ripple Persistence" do
  require 'support/test_server'

  before :all do    
    Object.module_eval do
      class Widget
        include Ripple::Document
        property :name, String
        property :size, Integer
      end
    end
  end
  
  before :each do
    @widget = Widget.new
  end
  
  it "should save an object to the riak database" do
    @widget.save
    @found = Widget.find(@widget.key)
    @found.should be_a(Widget)
  end
  
  it "should save attributes properly to riak" do
    @widget.attributes = {:name => 'Sprocket', :size => 10}
    @widget.save
    @found = Widget.find(@widget.key)
    @found.name.should == 'Sprocket'
    @found.size.should == 10
  end
  
  after :each do
    Widget.destroy_all
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
  
end
