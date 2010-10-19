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

describe Ripple::Conversion do
  require 'support/models/box'

  before :each do
    @box = Box.new { |a| a.key = 'some-key' }
    @box.stub!(:new?).and_return(false)
  end

  it "should return the key as an array for to_key" do
    @box.to_key.should == ['some-key']
  end

  it "should be able to be converted to a param" do
    @box.to_param.should == 'some-key'
  end

  it "should be able to be converted to a model" do
    @box.to_model.should == @box
  end
end
