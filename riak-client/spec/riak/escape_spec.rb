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

describe Riak::Util::Escape do
  before :each do
    @object = Object.new
    @object.extend(Riak::Util::Escape)
  end

  it "should escape standard non-safe characters" do
    @object.escape("some string").should == "some%20string"
    @object.escape("another^one").should == "another%5Eone"
    @object.escape("bracket[one").should == "bracket%5Bone"
  end

  it "should escape slashes" do
    @object.escape("some/inner/path").should == "some%2Finner%2Fpath"
  end
  
  it "should convert the bucket or key to a string before escaping" do
    @object.escape(125).should == '125'
  end
end
