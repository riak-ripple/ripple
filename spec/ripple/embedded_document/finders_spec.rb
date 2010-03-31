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

describe Ripple::EmbeddedDocument::Finders do
  before :all do
    Object.module_eval { class Address; include Ripple::EmbeddedDocument; end }
  end

  before :each do
    @root = mock("root document")
    @root.stub!(:new?).and_return(true)
    @addr = Address.new
    @addr._root_document = @root
  end

  it "should instantiate a document"
  
  it "should set the root document when instantiating"
  
  it "should instantiate a class of _type if being called from Ripple::EmbeddedDocument"
  
  it "should use self if being called from a class including Ripple::EmbeddedDocument"

  after :all do
    Object.send(:remove_const, :Address)
  end
end
