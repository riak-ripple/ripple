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

describe Ripple::Observer do
  require 'support/models/box'
  require 'support/models/box_observer'

  before :each do
      response  = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
      @client   = Ripple.client
      @http     = mock("HTTP Backend", :get => response, :put => response, :post => response, :delete => response)
      @client.stub!(:http).and_return(@http)
      @box      = Box.new
      @observer = BoxObserver.instance
  end

  context "given a document is created" do
    it "should notify all observers twice" do
      Box.should_receive(:notify_observers).twice
      @box.save
    end

    context "before creating the document" do
      it "should call Observer#before_create" do
        @observer.should_receive(:before_create)
        @box.save
      end
    end

    context "after creating the document" do
      it "should call Observer#after_create" do
        @observer.should_receive(:after_create)
        @box.save
      end
    end
  end

  context "given a document is updated" do
    before(:each) do
      @box.stub!(:new?).and_return(false)
    end

    it "should notify all observers twice" do
      Box.should_receive(:notify_observers).twice
      @box.save
    end

    context "before updating the document" do
      it "should call Observer#before_update" do
        @observer.should_receive(:before_update)
        @box.save
      end
    end

    context "after updating the document" do
      it "should call Observer#after_update" do
        @observer.should_receive(:after_update)
        @box.save
      end
    end
  end

  context "given a document is destroyed" do
    it "should notify all observers twice" do
      Box.should_receive(:notify_observers).twice
      @box.destroy
    end

    context "before destroying the document" do
      it "should call Observer#before_destroy" do
        @observer.should_receive(:before_destroy)
        @box.destroy
      end
    end

    context "after destroy the document" do
      it "should call Observer#after_destroy" do
        @observer.should_receive(:after_destroy)
        @box.destroy
      end
    end
  end
end
