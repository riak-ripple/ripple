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
  before :all do
    Object.module_eval {
      class Widget
        include Ripple::Document
        property :size, Integer
        property :name, String, :default => "widget"
      end
    }
  end

  before :each do
    @http = mock("HTTP Backend")
    @client = Ripple.client
    @client.stub!(:http).and_return(@http)
    @bucket = Riak::Bucket.new(@client, "widgets")
    @client.stub!(:[]).and_return(@bucket)
    @widget = Widget.new(:size => 1000)
  end

  it "should save a new object to Riak" do
    json = @widget.attributes.merge("_type" => "Widget").to_json
    @http.should_receive(:post).with(201, "/riak/", "widgets", an_instance_of(Hash), json, hash_including("Content-Type" => "application/json")).and_return(:code => 201, :headers => {'location' => ["/riak/widgets/new_widget"]})
    @widget.save
    @widget.key.should == "new_widget"
    @widget.should_not be_new_record
    @widget.changes.should be_blank
  end

  it "should reload a saved object" do
    json = @widget.attributes.merge("_type" => "Widget").to_json
    @http.should_receive(:post).with(201, "/riak/", "widgets", an_instance_of(Hash), json, hash_including("Content-Type" => "application/json")).and_return(:code => 201, :headers => {'location' => ["/riak/widgets/new_widget"]})
    @widget.save
    @http.should_receive(:get).and_return(:code => 200, :headers => {'content-type' => ["application/json"]}, :body => '{"name":"spring","size":10}')
    @widget.reload
    @widget.changes.should be_blank
    @widget.name.should == "spring"
    @widget.size.should == 10
  end

  it "should destroy a saved object" do
    @http.should_receive(:post).and_return(:code => 201, :headers => {'location' => ["/riak/widgets/new_widget"]})
    @widget.save
    @http.should_receive(:delete).and_return(:code => 204, :headers => {})
    @widget.destroy.should be_true
    @widget.should be_frozen
  end

  it "should freeze an unsaved object when destroying" do
    @http.should_not_receive(:delete)
    @widget.destroy.should be_true
    @widget.should be_frozen
  end

  describe "when storing a class using single-bucket inheritance" do
    before :all do
      Object.module_eval { class Cog < Widget; property :name, String, :default => "cog"; end }
    end

    before :each do
      @cog = Cog.new(:size => 1000)
    end

    it "should store the _type field as the class name" do
      json = @cog.attributes.merge("_type" => "Cog").to_json
      @http.should_receive(:post).and_return(:code => 201, :headers => {'location' => ["/riak/widgets/new_widget"]})
      @cog.save
      @cog.should_not be_new_record
    end

    after :all do
      Object.send(:remove_const, :Cog)
    end
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
end
