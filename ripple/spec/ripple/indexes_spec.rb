require 'spec_helper'

describe Ripple::Indexes do
  context "class methods" do
    subject { Indexer }
    it { should respond_to(:indexes) }
    it { should have(2).indexes }

    it "should remove the :index key from the property options" do
      subject.properties[:name].options.should_not include(:index)
      subject.properties[:age].options.should_not include(:index)
    end
  end

  context "instance methods" do
    before { subject.robject.stub!(:store).and_return(true) }
    subject { Indexer.new(:name => "Bob", :age => 28) }
    it { should respond_to(:indexes_for_persistence) }
    its(:indexes_for_persistence) { should include('age_int') }
    its(:indexes_for_persistence) { should include('name_bin') }
    its(:indexes_for_persistence) { should be_all {|_,i| i.kind_of?(Set) } }

    it "should set the indexes on the internal Riak object when saving" do
      subject.save
      subject.robject.indexes.should_not be_empty
      subject.robject.indexes["name_bin"].should == Set["Bob"]
      subject.robject.indexes["age_int"].should == Set[28]
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
  
  it "should raise an error when the index type cannot be determined" do
    klass = Class.new
    expect { Ripple::Index.new('foo', klass).index_type }.to raise_error(ArgumentError)
  end

  it "should use the specified index type" do
    Ripple::Index.new('foo', Time, 'bin').index_type.should == 'bin'
  end

  it "should provide an index key that includes the type" do
    Ripple::Index.new('foo', Integer).index_key.should == 'foo_int'
    Ripple::Index.new('foo', String).index_key.should == 'foo_bin'
  end
end
