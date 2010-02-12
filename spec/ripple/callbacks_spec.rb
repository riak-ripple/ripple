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

describe Ripple::Document::Persistence::Callbacks do
  before :all do
    Object.module_eval { class Box; include Ripple::Document; property :shape, String end }
  end

  it "should add create, update, save, and destroy callback declarations" do
    [:save, :create, :update, :destroy].each do |event|
      Box.private_instance_methods.map(&:to_s).should include("_run_#{event}_callbacks")
      [:before, :after, :around].each do |time|
        Box.should respond_to("#{time}_#{event}")
      end
    end
  end

  describe "invoking callbacks" do
    before :each do
      response = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
      @client = Ripple.client
      @http = mock("HTTP Backend", :get => response, :put => response, :post => response, :delete => response)
      @client.stub!(:http).and_return(@http)
      $pinger = mock("callback verifier")
    end

    it "should call save callbacks on save" do
      Box.before_save { $pinger.ping }
      Box.after_save { $pinger.ping }
      Box.around_save(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.save
    end

    it "should call create callbacks on save when the document is new" do
      Box.before_create { $pinger.ping }
      Box.after_create { $pinger.ping }
      Box.around_create(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.save
    end

    it "should call update callbacks on save when the document is not new" do
      Box.before_update { $pinger.ping }
      Box.after_update { $pinger.ping }
      Box.around_update(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.stub!(:new?).and_return(false)
      @box.save
    end

    it "should call destroy callbacks" do
      Box.before_destroy { $pinger.ping }
      Box.after_destroy { $pinger.ping }
      Box.around_destroy(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.destroy
    end

    after :each do
      [:save, :create, :update, :destroy].each do |type|
        Box.reset_callbacks(type)
      end
    end
  end

  after :all do
    Object.send(:remove_const, :Box)
  end
end
