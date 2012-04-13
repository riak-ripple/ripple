require 'spec_helper'

describe Ripple::Indexes do
  context "finding documents by an index" do
    before do
      @bob = Indexer.create(:name => "Bob", :age => 28)
      @sally = Indexer.create(:name => "Sally", :age => 28)
      @mary = Indexer.create(:name => "Mary", :age => 25)
    end

    it "should find a document by equality" do
      Indexer.find_by_index(:name, 'Bob').should == [@bob]
    end

    it "should find many documents by equality" do
      Indexer.find_by_index(:age, 28).should =~ [@bob, @sally]
    end

    it "should find nothing by equality" do
      Indexer.find_by_index(:age, 30).should == []
    end

    it "should find a document by range" do
      Indexer.find_by_index(:name, "B".."C").should == [@bob]
    end

    it "should find many documents by range" do
      Indexer.find_by_index(:age, 27..29).should =~ [@bob, @sally]
    end

    it "should find nothing by range" do
      Indexer.find_by_index(:age, 10..20).should == []
    end

    it "should find by the special $bucket index" do
      Indexer.find_by_index('$bucket', Indexer.bucket.name).should =~ [@bob, @sally, @mary]
    end

    it "should find by the special $key index" do
      Indexer.find_by_index('$key', @bob.key..@bob.key.succ).should =~ [@bob]
    end

    it "should raise an error when the requested index doesn't exist" do
      lambda { Indexer.find_by_index(:hair, 'blonde') }.should raise_error(ArgumentError)
    end
  end
end
