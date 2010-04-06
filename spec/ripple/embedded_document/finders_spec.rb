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
  class Address; include Ripple::EmbeddedDocument; end 
  class Favorite; include Ripple::EmbeddedDocument; end

  before :each do
    @addr = Address.new
  end

  it "should instantiate a document" do
    Address.stub!(:new).and_return(@address)
    Address.instantiate('_type' => 'Address').should == @address
  end
  
  it "should instantiate a class of _type if present in attrs" do
    Favorite.instantiate('_type' => 'Address').class.should == Address
  end
  
  it "should use self if being called from a class including Ripple::EmbeddedDocument and _type is not present" do
    Address.instantiate({}).class.should == Address
  end

end
