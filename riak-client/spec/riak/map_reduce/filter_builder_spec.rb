# Copyright 2010-2011 Sean Cribbs and Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Riak::MapReduce::FilterBuilder do
  subject { Riak::MapReduce::FilterBuilder.new }
  it "should evaluate the passed block on initialization" do
    subject.class.new do
      matches "foo"
    end.to_a.should == [[:matches, "foo"]]
  end

  it "should add filters to the list" do
    subject.to_lower
    subject.similar_to("ripple", 3)
    subject.to_a.should == [[:to_lower],[:similar_to, "ripple", 3]]
  end

  it "should add a logical operation with a block" do
    subject.OR do
      starts_with "foo"
      ends_with "bar"
    end
    subject.to_a.should == [[:or, [[:starts_with, "foo"],[:ends_with, "bar"]]]]
  end

  it "should raise an error on a filter arity mismatch" do
    lambda { subject.less_than }.should raise_error(ArgumentError)
  end

  it "should raise an error when a block is not given to a logical operation" do
    lambda { subject._or }.should raise_error(ArgumentError)
  end
end
