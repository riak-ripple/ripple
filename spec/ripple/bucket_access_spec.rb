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
  before :all do
    Object.module_eval do
      class Invoice; include Ripple::Document; end
      class LateInvoice < Invoice; end
      class PaidInvoice < Invoice; self.bucket_name = "paid"; end
    end
  end

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
    bucket = Riak::Bucket.new(Ripple.client, "invoices")
    Ripple.client.should_receive(:[]).with("invoices", {:keys => false}).and_return(bucket)
    Invoice.bucket.should == bucket
  end

  after :all do
    Object.module_eval do
      remove_const(:PaidInvoice)
      remove_const(:LateInvoice)
      remove_const(:Invoice)
    end
  end
end
