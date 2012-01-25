require 'spec_helper'

describe Ripple::Associations::ManyReferenceProxy do
  # require 'support/models/transactions'

  before :each do
    @account = Account.new {|e| e.key = "accounty"}
    @payment_method = PaymentMethod.new {|e| e.key = "paymadoo"}
    @other_payment_method = PaymentMethod.new {|e| e.key = "otherpaym"}
    Ripple.client.stub(:search => {"response" => {"docs" => []}})
  end

  it "should be empty before any associated documents are set" do
    @account.payment_methods.should be_empty
  end

  it "should accept an array of documents" do
    @account.payment_methods = [@payment_method]
  end

  it "should set the key on the sub object when assigning" do
    @account.payment_methods = [@payment_method]
    @payment_method.account_key.should == "accounty"
  end

  it "should be able to replace the entire collection of documents (even appended ones)" do
    @account.payment_methods << @payment_method
    @account.payment_methods = [@other_payment_method]
    @account.payment_methods.should == [@other_payment_method]
  end

  it "should return the assigned documents when assigning" do
    t = (@account.payment_methods = [@payment_method])
    t.should == [@payment_method]
  end

  it "should find the associated documents when accessing" do
    Ripple.client.should_receive(:search).with("payment_methods", "account_key: accounty").and_return({"response" => {"docs" => ["id" => "paymadoo"]}})
    PaymentMethod.should_receive(:find).with(["paymadoo"]).and_return([@payment_method])
    @account.payment_methods.should == [@payment_method]
  end

  it "should replace associated documents with a new set" do
    @account.payment_methods = [@payment_method]
    @account.payment_methods = [@other_payment_method]
    @account.payment_methods.should == [@other_payment_method]
  end

  it "should return an array from to_ary" do
    @account.payment_methods << @payment_method
    @account.payment_methods.to_ary.should == [@payment_method]
  end

  it "should refuse assigning a collection of the wrong type" do
    lambda { @account.payment_methods = nil }.should raise_error
    lambda { @account.payment_methods = @payment_method }.should raise_error
    lambda { @account.payment_methods = [@account] }.should raise_error
  end

  describe "#<< (when the target has not already been loaded)" do
    it "avoids searching when adding a record to an unloaded association" do
      PaymentMethod.should_not_receive(:search)
      @account.payment_methods << @payment_method
    end

    it "should be able to count the associated documents" do
      @account.payment_methods << @payment_method
      @account.payment_methods.count.should == 1
      @account.payment_methods << @other_payment_method
      @account.payment_methods.count.should == 2
    end

    it "should be able to count without loading documents" do
      Ripple.client.stub(:search => {"response" => {"docs" => [{"id" => @payment_method.key}, {"id" => @other_payment_method.key}]}})
      PaymentMethod.should_not_receive(:find)
      @account.payment_methods.count.should == 2
    end

    it "should be able to append documents to the associated set" do
      @account.payment_methods << @payment_method
      @account.payment_methods << @other_payment_method
      @account.should have(2).payment_methods
    end

    it "should be able to chain calls to adding documents" do
      @account.payment_methods << @payment_method << @other_payment_method
      @account.should have(2).payment_methods
    end

    it "should assign the keys on the sub object when appending" do
      @account.payment_methods << @payment_method << @other_payment_method
      [@payment_method, @other_payment_method].each do |t|
        t.account_key.should == "accounty"
      end
    end

    it "does not return duplicates (for when the object has been appended and it's robject is found while walking the links)" do
      @account.payment_methods.stub(:find_target => Set.new([@payment_method]))
      @account.payment_methods.reset
      @account.payment_methods << @payment_method
      @account.payment_methods.should == [@payment_method]
    end
  end

  describe "#reset" do
    it "clears appended documents" do
      @account.payment_methods << @payment_method
      @account.payment_methods.reset
      @account.payment_methods.should == []
    end
  end

  describe "#keys" do
    let(:ze_keys) { %w(1 2 3) }
    let(:search_results) do
      {"response" => {"docs" => ze_keys.map { |k| {"id" => k} }}}
    end

    before(:each) do
      Ripple.client.stub(:search => search_results)
      PaymentMethod.stub(:find => [@payment_method])
    end

    it "returns a set of keys" do
      @account.payment_methods.keys.should be_a(Set)
      @account.payment_methods.keys.to_a.should =~ ze_keys
    end

    it "is memoized between calls" do
      @account.payment_methods.keys.should equal(@account.payment_methods.keys)
    end

    it "is cleared when the association is reset" do
      orig_set = @account.payment_methods.keys
      @account.payment_methods.reset
      @account.payment_methods.keys.should_not equal(orig_set)
    end

    it "is cleared when the association is replaced" do
      orig_set = @account.payment_methods.keys
      @account.payment_methods.replace([@payment_method])
      @account.payment_methods.keys.should_not equal(orig_set)
    end

    it "maintains the list of keys properly as new documents are appended" do
      @account.payment_methods << @payment_method
      @account.payment_methods.should have(1).key
      @account.payment_methods << @other_payment_method
      @account.payment_methods.should have(2).keys
    end
  end

  describe "#include?" do
    it "delegates to the set of keys so as not to unnecessarily load the associated documents" do
      @account.payment_methods.keys.should_receive(:include?).with(@payment_method.key).and_return(true)
      @account.payment_methods.include?(@payment_method).should be_true
    end

    it "short-circuits and returns false if the given object is not a ripple document" do
      @account.payment_methods.keys.should_not_receive(:include?)
      @account.payment_methods.include?(Object.new).should be_false
    end

    it "returns false if the document's bucket is different from the associations bucket, even if the keys are the same" do
      @account.payment_methods << @payment_method
      other_account = Account.new { |p| p.key = @payment_method.key }
      @account.payment_methods.include?(other_account).should be_false
    end
  end
end
