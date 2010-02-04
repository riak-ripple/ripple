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
    class Widget
      include Ripple::Document
      property :size, Integer
      property :name, String, :default => "widget"
    end
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
    json = @widget.attributes.to_json
    @http.should_receive(:post).with(201, "/raw/", "widgets", an_instance_of(Hash), json, hash_including("Content-Type" => "application/json")).and_return(:code => 201, :headers => {'location' => ["/raw/widgets/new_widget"]})
    @widget.save
    @widget.key.should == "new_widget"
    @widget.should_not be_new_record
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
end
