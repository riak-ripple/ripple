require 'spec_helper'

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
