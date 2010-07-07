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
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Ripple::Document::BucketAccess do
  require 'support/models/invoice'
  require 'support/models/late_invoice'
  require 'support/models/paid_invoice'

  it "should use the plural model name as the bucket name" do
    Invoice.bucket_name.should == "invoices"
  end

  it "should use the parent bucket name by default (SBI)" do
    LateInvoice.bucket_name.should == "invoices"
  end

  it "should allow a class to set the bucket name" do
    PaidInvoice.bucket_name.should == "paid"
  end

  it "should allow access to the bucket" do
    Invoice.bucket.should be_kind_of(Riak::Bucket)
    Invoice.bucket.client.should == Ripple.client
    Invoice.bucket.name.should == "invoices"
  end
end
