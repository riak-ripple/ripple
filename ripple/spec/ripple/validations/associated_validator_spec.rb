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

describe Ripple::Validations::AssociatedValidator do
  require 'support/models/family'

  let(:child)  { Child.new  }
  let(:parent) { Parent.new }
  before(:each) { parent.child = child }

  it "is invalid when the associated record is invalid" do
    child.should_not be_valid
    parent.should_not be_valid
  end

  it "is valid when the associated record is valid" do
    child.name = 'Coen'
    child.should be_valid
    parent.should be_valid
  end
end
