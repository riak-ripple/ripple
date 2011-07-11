require File.expand_path("../../../spec_helper", __FILE__)

describe Ripple::Associations::OneStoredKeyProxy do
  require 'support/models/transactions'

  before :each do
    @account = Account.new {|p| p.key = "accounty" }
    @transaction = Transaction.new
  end

  it "should be blank before the associated document is set" do
    @transaction.account.should_not be_present
  end

  it "should accept a single document" do
    lambda { @transaction.account = @account }.should_not raise_error
  end

  it "should set the key when assigning" do
    @transaction.account = @account
    @transaction.account_key.should == "accounty"
  end

  it "should return the assigned document when assigning" do
    ret = (@transaction.account = @account)
    ret.should == @account
  end

  it "should find the associated document when accessing" do
    @transaction.account_key = "accounty"
    Account.should_receive(:find).with("accounty").and_return(@account)
    @transaction.account.should be_present
  end

  it "should return nil immediately if the association link is missing" do
    @transaction.account_key.should be_nil
    @transaction.account.should be_nil
  end

  it "should resolve conflicts"
end