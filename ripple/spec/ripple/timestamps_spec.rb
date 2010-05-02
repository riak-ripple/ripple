require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ripple::Document::Timestamps do
  require 'support/models/clock'
  
  before :each do
    response = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
    @client = Ripple.client
    @http = mock("HTTP Backend", :get => response, :put => response, :post => response, :delete => response)
    @client.stub!(:http).and_return(@http)
    @clock = Clock.new
  end
  
  it "should add a created_at property" do
    @clock.should respond_to(:created_at)
  end
  
  it "should add an updated_at property" do
    @clock.should respond_to(:updated_at)
  end
  
  it "should set the created_at timestamp when the object is initialized" do
    @clock.created_at.should_not be_nil
  end
  
  it "should not set the updated_at timestamp when the object is initialized" do
    @clock.updated_at.should be_nil
  end
  
  it "should set the updated_at timestamp when the object is created" do
    @clock.save
    @clock.updated_at.should_not be_nil
  end
  
  it "should update the updated_at timestamp when the object is updated" do
    @clock.save
    start = @clock.updated_at
    @clock.save
    @clock.updated_at.should > start
  end
  
end
