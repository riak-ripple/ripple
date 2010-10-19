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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ripple::Timestamps do
  require 'support/models/clock'
  
  before :each do
    response = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
    @client = Ripple.client
    @http = mock("HTTP Backend", :get => response, :put => response, :post => response, :delete => response)
    @client.stub!(:http).and_return(@http)
    @clock = Clock.new
  end
  
  it "should add a created_at property" do
    @clock.should respond_to(:created_at)
  end
  
  it "should add an updated_at property" do
    @clock.should respond_to(:updated_at)
  end
  
  it "should set the created_at timestamp when the object is initialized" do
    @clock.created_at.should_not be_nil
  end
  
  it "should not set the updated_at timestamp when the object is initialized" do
    @clock.updated_at.should be_nil
  end
  
  it "should set the updated_at timestamp when the object is created" do
    @clock.save
    @clock.updated_at.should_not be_nil
  end
  
  it "should update the updated_at timestamp when the object is updated" do
    @clock.save
    start = @clock.updated_at
    @clock.save
    @clock.updated_at.should > start
  end
  
end
