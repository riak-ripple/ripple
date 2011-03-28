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

describe Ripple::Validations do
  require 'support/models/box'

  before :each do
    @box = Box.new
    @client = Ripple.client
    @client.stub!(:backend).and_return(mock("Backend", :store_object => true))
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

  it "should allow skipping validations by passing save :validate => false" do
    Ripple.client.http.stub!(:perform).and_return(mock_response)
    @box.should_not_receive(:valid?)
    @box.save(:validate => false).should be_true
  end

  describe "when using save! on an invalid record" do
    before(:each) { @box.stub!(:valid?).and_return(false) }

    it "should raise DocumentInvalid" do
      lambda { @box.save! }.should raise_error(Ripple::DocumentInvalid)
    end

    it "should raise an exception that has the invalid document" do
      begin
        @box.save!
      rescue Ripple::DocumentInvalid => invalid
        invalid.document.should == @box
      end
    end
  end

  it "should not raise an error when save! is called and the document is valid" do
    @box.stub!(:save).and_return(true)
    @box.stub!(:valid?).and_return(true)
    lambda { @box.save! }.should_not raise_error(Ripple::DocumentInvalid)
  end

  it "should return true from save! when no exception is raised" do
    @box.stub!(:save).and_return(true)
    @box.stub!(:valid?).and_return(true)
    @box.save!.should be_true
  end

  it "should allow unexpected exceptions to be raised" do
    robject = mock("robject", :key => @box.key, "data=" => true)
    robject.should_receive(:store).and_raise(Riak::HTTPFailedRequest.new(:post, 200, 404, {}, "404 not found"))
    @box.stub!(:robject).and_return(robject)
    @box.stub!(:valid?).and_return(true)
    lambda { @box.save! }.should raise_error(Riak::FailedRequest)
  end

  it "should not raise an error when creating a box with create! succeeds" do
    @box.stub!(:new?).and_return(false)
    Box.stub(:create).and_return(@box)
    lambda { @new_box = Box.create! }.should_not raise_error(Ripple::DocumentInvalid)
    @new_box.should == @box
  end

  it "should raise an error when creating a box with create! fails" do
    @box.stub!(:new?).and_return(true)
    Box.stub(:create).and_return(@box)
    lambda { Box.create! }.should raise_error(Ripple::DocumentInvalid)
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
end
