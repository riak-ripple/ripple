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

describe Ripple::Document::Persistence do
  require 'support/models/widget'

  before :each do
    @backend = mock("Backend")
    @client = Ripple.client
    @client.stub!(:backend).and_return(@backend)
    @bucket = Ripple.client.bucket("widgets")
    @widget = Widget.new(:size => 1000)
  end

  it "should save a new object to Riak" do
    json = @widget.attributes.merge("_type" => "Widget").to_json
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.raw_data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.save
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
  end

  it "should modify attributes and save a new object" do
    json = @widget.attributes.merge("_type" => "Widget", "size" => 5).to_json
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.raw_data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.update_attributes(:size => 5)
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
  end

  it "should modify a single attribute and save a new object" do
    json = @widget.attributes.merge("_type" => "Widget", "size" => 5).to_json
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.raw_data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.update_attribute(:size, 5)
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
    @widget.size.should == 5
  end

  it "should instantiate and save a new object to riak" do
    json = @widget.attributes.merge(:size => 10, :shipped_at => "2000-01-01T20:15:01Z", :_type => 'Widget').to_json
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.raw_data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget = Widget.create(:size => 10, :shipped_at => Time.utc(2000,"jan",1,20,15,1))
    @widget.size.should == 10
    @widget.shipped_at.should == Time.utc(2000,"jan",1,20,15,1)
    @widget.should_not be_a_new_record
  end

  it "should instantiate and save a new object to riak and allow its attributes to be set via a block" do
    json = @widget.attributes.merge(:size => 10, :_type => 'Widget').to_json
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.raw_data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget = Widget.create do |widget|
      widget.size = 10
    end
    @widget.size.should == 10
    @widget.should_not be_a_new_record
  end

  it "should save the attributes not having a corresponding property" do
    attrs = @widget.attributes.merge("_type" => "Widget", "unknown_property" => "a_value")
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == attrs
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget["unknown_property"] = "a_value"
    @widget.save
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
  end

  it "should allow unexpected exceptions to be raised" do
    robject = mock("robject", :key => @widget.key, "data=" => true)
    robject.should_receive(:store).and_raise(Riak::HTTPFailedRequest.new(:post, 200, 404, {}, "404 not found"))
    @widget.stub!(:robject).and_return(robject)
    lambda { @widget.save }.should raise_error(Riak::FailedRequest)
  end

  it "should reload a saved object" do
    json = @widget.attributes.merge(:_type => "Widget").to_json
    @backend.should_receive(:store_object) do |obj, _, _, _|
      obj.raw_data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.save
    @backend.should_receive(:reload_object) do |obj, _|
      obj.key.should == "new_widget"
      obj.raw_data = '{"name":"spring","size":10,"shipped_at":"Sat, 01 Jan 2000 20:15:01 -0000","_type":"Widget"}'
    end
    @widget.reload
    @widget.changes.should be_blank
    @widget.name.should == "spring"
    @widget.size.should == 10
    @widget.shipped_at.should == Time.utc(2000,"jan",1,20,15,1)
  end

  it "should destroy a saved object" do
    @backend.should_receive(:store_object).and_return(true)
    @widget.key = "foo"
    @widget.save
    @widget.should_not be_new
    @backend.should_receive(:delete_object).and_return(true)
    @widget.destroy.should be_true
    @widget.should be_frozen
  end

  it "should destroy all saved objects" do
    @widget.should_receive(:destroy).and_return(true)
    Widget.should_receive(:all).and_yield(@widget)
    Widget.destroy_all.should be_true
  end

  it "should freeze an unsaved object when destroying" do
    @backend.should_not_receive(:delete_object)
    @widget.destroy.should be_true
    @widget.should be_frozen
  end

  it "should be a root document" do
    @widget._root_document.should == @widget
  end

  describe "when storing a class using single-bucket inheritance" do
    before :each do
      @cog = Cog.new(:size => 1000)
    end

    it "should store the _type field as the class name" do
      json = @cog.attributes.merge("_type" => "Cog").to_json
      @backend.should_receive(:store_object) do |obj, _, _, _|
        obj.raw_data.should == json
        obj.key = "new_widget"
      end
      @cog.save
      @cog.should_not be_new_record
    end
  end

  describe "modifying the default quorum values" do
    before :each do
      Widget.set_quorums :r => 1, :w => 1, :dw => 0, :rw => 1
      @bucket = mock("bucket", :name => "widgets")
      @robject = mock("object", :data => {"name" => "bar"}, :key => "gear")
      Widget.stub(:bucket).and_return(@bucket)
    end

    it "should use the supplied R value when reading" do
      @bucket.should_receive(:get).with("gear", :r => 1).and_return(@robject)
      Widget.find("gear")
    end

    it "should use the supplied W and DW values when storing" do
      Widget.new do |widget|
        widget.key = "gear"
        widget.send(:robject).should_receive(:store).with({:w => 1, :dw => 0})
        widget.save
      end
    end

    it "should use the supplied RW when deleting" do
      widget = Widget.new
      widget.key = "gear"
      widget.instance_variable_set(:@new, false)
      widget.send(:robject).should_receive(:delete).with({:rw => 1})
      widget.destroy
    end
  end
end
