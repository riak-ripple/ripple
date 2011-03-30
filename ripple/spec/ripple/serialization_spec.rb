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

describe Ripple::Serialization, :focus => true do
  require 'support/models/invoice'
  require 'support/models/note'
  require 'support/models/customer'

  it "should provide JSON serialization" do
    Invoice.new.should respond_to(:to_json)
  end

  context "when serializing" do
    it "should include attributes" do
      Note.new(:text => "Dear Jane,...").serializable_hash.should include('text')
    end

    it "should include the document key" do
      doc = Invoice.new
      doc.key = "1"
      doc.serializable_hash['key'].should == "1"
    end

    it "should include embedded documents by default" do
      doc = Invoice.new(:note => {:text => "Dear customer,..."}).serializable_hash
      doc['note'].should eql({'text' => "Dear customer,..."})
    end

    it "should exclude specified attributes" do
      hash = Invoice.new.serializable_hash(:except => [:created_at])
      hash.should_not include('created_at')
    end

    it "should limit to specified attributes" do
      hash = Invoice.new.serializable_hash(:only => [:created_at])
      hash.should include('created_at')
      hash.should_not include('updated_at')
    end
  end
end
