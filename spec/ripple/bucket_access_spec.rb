require 'spec_helper'

describe Ripple::Document::BucketAccess do
  # require 'support/models/invoice'
  # require 'support/models/late_invoice'
  # require 'support/models/paid_invoice'

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
