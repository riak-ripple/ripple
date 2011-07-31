require 'spec_helper'

describe "Ripple Search Associations", :integration => true, :search => true do
  before :all do
    Object.module_eval do
      class Transaction
        include Ripple::Document
        property :account_key, String
        property :name, String
      end
      class Account
        include Ripple::Document
        many :transactions, :using => :reference
        property :email, String
      end
    end
  end

  before :each do
    @account      = Account.new(:email => 'riak@ripple.com')
    @transaction1 = Transaction.new(:name => 'One')
    @transaction2 = Transaction.new(:name => 'Two')
  end

  it "should save a many referenced association" do
    @account.save!
    @account.transactions << @transaction1 << @transaction2
    @transaction1.save!
    @transaction2.save!
    @found = Account.find(@account.key)
    @found.transactions.map(&:key).should include(@transaction1.key)
    @found.transactions.map(&:key).should include(@transaction2.key)
  end

  after :all do
    Object.send(:remove_const, :Account)
    Object.send(:remove_const, :Transaction)
  end
end
