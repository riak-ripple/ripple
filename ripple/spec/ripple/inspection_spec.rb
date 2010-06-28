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

describe Ripple::Inspection do
  require 'support/models/box'
  require 'support/models/address'

  before :each do
    @box = Box.new
    @address = Address.new
  end
  
  it "should include the class name in the inspect string" do
    @box.inspect.should be_starts_with("<Box")
  end
  
  it "should include the key in the inspect string for documents" do
    @box.key = "square"
    @box.inspect.should be_starts_with("<Box:square")
  end
  
  it "should indicate a new document when no key is specified" do
    @box.inspect.should be_starts_with("<Box:[new]")
  end

  it "should enumerate the document's properties and their values" do
    @box.shape = "square"
    @box.inspect.should include("shape=\"square\"")
    @box.inspect.should include("created_at=")
    @box.inspect.should include("updated_at=")
  end
  
  it "should not display a key for embedded documents" do
    @address.inspect.should_not include("[new]")
  end
end
