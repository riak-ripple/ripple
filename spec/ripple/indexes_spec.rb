require 'spec_helper'

describe Ripple::Indexes do
  context "class methods" do
    subject { Indexer }
    it { should respond_to(:indexes) }
    it { should have(4).indexes }

    it "should remove the :index key from the property options" do
      subject.properties[:name].options.should_not include(:index)
      subject.properties[:age].options.should_not include(:index)
    end

    it "should not have a property for synthetic indexes" do
      subject.properties[:name_age].should == nil
      subject.properties[:name_greeting].should == nil
    end
  end

  context "inherited indexes" do
    subject { SubIndexer }
    it { should have(5).indexes }
    it "should have inherited indexes" do
      subject.indexes.keys.should include('age', 'name', 'name_age', 'name_greeting')
    end
    it "should have indexes defined on the subclass" do
      subject.indexes.keys.should include('height')
    end
  end

  context "instance methods" do
    before { subject.robject.stub!(:store).and_return(true) }
    subject { Indexer.new(:name => "Bob", :age => 28) }
    it { should respond_to(:indexes_for_persistence) }
    its(:indexes_for_persistence) { should include('age_int') }
    its(:indexes_for_persistence) { should include('name_bin') }
    its(:indexes_for_persistence) { should include('name_age_bin') }
    its(:indexes_for_persistence) { should include('name_greeting_bin') }
    its(:indexes_for_persistence) { should be_all {|_,i| i.kind_of?(Set) } }

    it "should set the indexes on the internal Riak object when saving" do
      subject.save
      subject.robject.indexes.should_not be_empty
      subject.robject.indexes["name_bin"].should == Set["Bob"]
      subject.robject.indexes["age_int"].should == Set[28]
      subject.robject.indexes["name_age_bin"].should == Set["Bob-28"]
      subject.robject.indexes["name_greeting_bin"].should == Set["Bob: Hello!"]
    end

    context "when an index value is nil" do
      subject { Indexer.new(:name => nil, :age => 28) }
      its(:indexes_for_persistence) { should_not include('name_bin') }
      its(:indexes_for_persistence) { should_not include('name_age_bin') }
      its(:indexes_for_persistence) { should_not include('name_greeting_bin') }
    end

    context "when embedded documents have indexes" do
      subject do
        Indexer.new(:name => "Bob",
                    :age => 28,
                    :addresses => [{:street => "10 Main St", :city => "Anywhere"},
                                   {:street => "100 W 10th Avenue", :city => "Springfield"}],
                    :primary_address => {
                      :street => "1 W 5th Place",
                      :city => "Independence"})
      end

      its(:indexes_for_persistence){ should include("primary_address_street_bin") }
      its(:indexes_for_persistence){ should include("primary_address_city_bin") }
      its(:indexes_for_persistence){ should include("addresses_street_bin") }
      its(:indexes_for_persistence){ should include("addresses_city_bin") }

      it "should merge indexes for many embedded associations" do
        subject.indexes_for_persistence['addresses_city_bin'].should == Set["Anywhere", "Springfield"]
        subject.indexes_for_persistence['addresses_street_bin'].should == Set["10 Main St", "100 W 10th Avenue"]
      end
    end
  end
end

describe Ripple::Index do
  it "should use a binary index when the type is a String" do
    Ripple::Index.new('foo', String).index_type.should == 'bin'
  end

  it "should use an integer index when the type is an Integer" do
    Ripple::Index.new('foo', Integer).index_type.should == 'int'
  end

  it "should use an integer index when the type is a time" do
    [Time, Date, ActiveSupport::TimeWithZone].each do |klass|
      Ripple::Index.new('foo', klass).index_type.should == 'int'
    end
  end

  it "should use an integer index when index type is Integer" do
    Ripple::Index.new('foo', String, Integer).index_type.should == 'int'
  end

  it "should use a binary index when index type is String" do
    Ripple::Index.new('foo', Integer, String).index_type.should == 'bin'
  end

  it "should raise an error when the index type cannot be determined" do
    klass = Class.new
    expect { Ripple::Index.new('foo', klass).index_type }.to raise_error(ArgumentError)
  end

  it "should use the specified index type" do
    Ripple::Index.new('foo', Time, 'bin').index_type.should == 'bin'
    Ripple::Index.new('foo', Time, String).index_type.should == 'bin'
    Ripple::Index.new('foo', Time, Integer).index_type.should == 'int'
  end

  it "should provide an index key that includes the type" do
    Ripple::Index.new('foo', Integer).index_key.should == 'foo_int'
    Ripple::Index.new('foo', String).index_key.should == 'foo_bin'
  end
end
