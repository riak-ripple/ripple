require 'spec_helper'

describe "Ripple Search Associations", :integration => true, :search => true do
  class SearchTransaction
    include Ripple::Document
    property :search_account_key, String
    property :name, String
  end

  class SearchAccount
    include Ripple::Document
    many :search_transactions, :using => :reference
    property :email, String
  end

  before :each do
    @account      = SearchAccount.new(:email => 'riak@ripple.com')
    @transaction1 = SearchTransaction.new(:name => 'One')
    @transaction2 = SearchTransaction.new(:name => 'Two')
  end

  it "should save a many referenced association" do
    @account.save!
    @account.search_transactions << @transaction1 << @transaction2
    @transaction1.save!
    @transaction2.save!
    @found = SearchAccount.find(@account.key)
    @found.search_transactions.map(&:key).should include(@transaction1.key)
    @found.search_transactions.map(&:key).should include(@transaction2.key)
  end
end
