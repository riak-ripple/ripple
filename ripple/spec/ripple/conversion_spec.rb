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
