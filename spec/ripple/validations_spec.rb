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

describe Ripple::Document::Validations do
  before :all do
    Object.module_eval { class Box; include Ripple::Document; property :shape, String end }
  end

  before :each do
    @box = Box.new
  end

  it "should add validation declarations to the class" do
    [:validates, :validate, :validates_with, :validates_each,
     :validates_acceptance_of, :validates_confirmation_of, :validates_exclusion_of,
     :validates_format_of, :validates_inclusion_of, :validates_length_of,
     :validates_numericality_of, :validates_presence_of].each do |meth|
      Box.should respond_to(meth)
    end
  end

  it "should add validation methods to the instance" do
    %w{errors valid? invalid?}.each do |meth|
      @box.should respond_to(meth)
    end
  end

  it "should override save to run validations" do
    @box.should_receive(:valid?).and_return(false)
    @box.save.should be_false
  end

  it "should automatically add validations from property options" do
    Box.property :size, Integer, :inclusion => {:in => 1..30 }
    @box.size = 0
    @box.should_not be_valid
    Box.properties.delete :size
  end

  it "should run validations at the correct lifecycle state" do
    Box.property :size, Integer, :inclusion => {:in => 1..30, :on => :update }
    @box.size = 0
    @box.should be_valid
    Box.properties.delete :size
  end
  
  after :each do
    Box.reset_callbacks(:validate)
  end
  
  after :all do
    Object.send(:remove_const, :Box)
  end
end
