require 'spec_helper'

describe Ripple::Associations::ManyStoredKeyProxy do
  # require 'support/models/transactions'

  before :each do
    @account = Account.new {|t| t.key = "accounty" }
    @transaction_one = Transaction.new {|t| t.key = "one" }
    @transaction_two = Transaction.new {|t| t.key = "two" }
    @transaction_three = Transaction.new {|t| t.key = "three" }
    @transaction_one.stub(:new_record?).and_return(false)
    @transaction_two.stub(:new_record?).and_return(false)
    @transaction_three.stub(:new_record?).and_return(false)
  end

  it "should be empty before any associated documents are set" do
    @account.transactions.should be_empty
  end

  it "should allow appending" do
    @account.transactions << @transaction_one
    @account.transactions.should == [@transaction_one]
    @account.transaction_keys.should == ["one"]
  end

  it "should be able to chain calls to adding documents" do
    @account.transactions << @transaction_one << @transaction_two
    @account.transactions.should == [@transaction_one, @transaction_two]
  end

  it "creates the right type of key collection" do
    Object.module_eval do
      class DifferentlyKeyedAccount
        include Ripple::Document
        property :transaction_keys, SortedSet
        many :transactions, :using => :stored_key
      end
    end

    account = DifferentlyKeyedAccount.new
    account.transactions << @transaction_one
    account.transaction_keys.should == SortedSet.new(["one"])
  end

  it "should accept an array of documents" do
    @account.transactions = [@transaction_one]
    @account.transactions.should == [@transaction_one]
    @account.transaction_keys.should == %w(one)
  end

  it "should be able to replace the entire collection of documents (even appended ones)" do
    @account.transactions << @transaction_one
    @account.transactions = [@transaction_two]
    @account.transactions.should == [@transaction_two]
    @account.transaction_keys.should == %w(two)
  end

  it "should return the assigned documents when assigning" do
    t = (@account.transactions = [@transaction_one])
    t.should == [@transaction_one]
  end

  it "asks the keys set for the count to avoid having to unnecessarily load all documents" do
    @account.transactions << @transaction_one
    @account.transaction_keys.stub(:size => 17)
    @account.transactions.count.should == 17
  end

  it "should return an array from to_ary" do
    @account.transactions << @transaction_one
    @account.transactions.to_ary.should == [@transaction_one]
  end

  it "should refuse assigning a collection of the wrong type" do
    lambda { @account.transactions = nil }.should raise_error
    lambda { @account.transactions = @transaction_one }.should raise_error
    lambda { @account.transactions = [@account] }.should raise_error
  end

  it "should refuse appending a document of the wrong type" do
    lambda { @account.transactions << Account.new }.should raise_error
  end

  describe "#reset" do
    it "clears appended documents" do
      @account.transactions << @transaction_one
      @account.transactions.reset
      @account.transactions.should == []
    end

    it "resets to the saved state of the proxy" do
      Transaction.stub(:find).and_return([@transaction_one])
      @account.transactions << @transaction_two
      @account.transactions.reset
      Transaction.stub(:find).and_return([@transaction_one])
      @account.transactions.should == [ @transaction_one ]
    end
  end

  describe "#include?" do
    it "delegates to the set of keys so as not to unnecessarily load the associated documents" do
      @account.transactions.keys.should_receive(:include?).with(@transaction_two.key).and_return(true)
      @account.transactions.include?(@transaction_two).should be_true
    end

    it "short-circuits and returns false if the given object is not a ripple document" do
      @account.transactions.keys.should_not_receive(:include?)
      @account.transactions.include?(Object.new).should be_false
    end

    it "returns false if the document's bucket is different from the associations bucket, even if the keys are the same" do
      @account.transactions << @transaction_one
      other_account = Account.new { |p| p.key = @transaction_one.key }
      @account.transactions.include?(other_account).should be_false
    end
  end

  describe "#keys" do
    before do
      @account.transactions << @transaction_one << @transaction_two
    end

    it "returns a set of keys" do
      @account.transactions.keys.should be_a(Array)
      @account.transactions.keys.to_a.should == %w(one two)
    end

    it "is memoized between calls" do
      @account.transactions.keys.should equal(@account.transactions.keys)
    end

    it "is cleared when the association is reset" do
      orig_set = @account.transactions.keys
      @account.transactions.reset
      @account.transactions.keys.should_not equal(orig_set)
      @account.transactions.keys.should == []
    end

    it "is cleared when the association is replaced" do
      orig_set = @account.transactions.keys
      @account.transactions.replace([@transaction_one])
      @account.transactions.keys.should_not equal(orig_set)
      @account.transactions.keys.to_a.should == %w(one)
    end

    it "maintains the list of keys properly as new documents are appended" do
      @account.transactions.keys.size.should == 2
      @account.transactions << @transaction_three
      @account.transactions.keys.size.should == 3
    end

  end

  it "temporarily bombs if the document you're appending isn't saved. This behavior shouldn't last long." do
    lambda { @account.transactions << Transaction.new }.should raise_error
  end

end
