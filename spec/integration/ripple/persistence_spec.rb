require 'spec_helper'

describe "Ripple Persistence" do
  before :each do
    @widget = Widget.new
  end

  it "should save an object to the riak database" do
    @widget.save
    @found = Widget.find(@widget.key)
    @found.should be_a(Widget)
  end

  it "should save attributes properly to riak" do
    @widget.attributes = {:name => 'Sprocket', :size => 10}
    @widget.save
    @found = Widget.find(@widget.key)
    @found.name.should == 'Sprocket'
    @found.size.should == 10
  end
end

describe Ripple::Document do
  let(:custom_data)        { Subscription::MyCustomType.new('bar') }
  let(:days_of_month)      { Set.new([1, 7, 15, 23]) }
  let(:subscription)       { Subscription.create!(:custom_data => custom_data, :days_of_month => days_of_month) }
  let(:found_subscription) { Subscription.find(subscription.key) }

  it 'allows properties with custom types to be saved and restored from riak' do
    found_subscription.custom_data.should == custom_data
  end

  it 'allows Set properties to be saved and restored from riak' do
    found_subscription.days_of_month.should == days_of_month
  end
end
