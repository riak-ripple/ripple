require File.expand_path("../../../spec_helper", __FILE__)

describe "Ripple Persistence" do
  require 'support/test_server'

  before :all do    
    Object.module_eval do
      class Widget
        include Ripple::Document
        property :name, String
        property :size, Integer
      end
    end
  end
  
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
  
  after :each do
    Widget.destroy_all
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
  
end
