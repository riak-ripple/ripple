require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ripple::Document::Timestamps do
  
  before :all do
    Object.module_eval { class Box; include Ripple::Document; property :shape, String; timestamps! end }
  end
  
  before :each do
    response = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
    @client = Ripple.client
    @http = mock("HTTP Backend", :get => response, :put => response, :post => response, :delete => response)
    @client.stub!(:http).and_return(@http)
    @box = Box.new
  end
  
  it "should add a created_at property" do
    @box.should respond_to(:created_at)
  end
  
  it "should add an updated_at property" do
    @box.should respond_to(:updated_at)
  end
  
  it "should set the created_at timestamp when the object is initialized" do
    @box.created_at.should_not be_nil
  end
  
  it "should not set the updated_at timestamp when the object is initialized" do
    @box.updated_at.should be_nil
  end
  
  it "should set the updated_at timestamp when the object is created" do
    @box.save
    @box.updated_at.should_not be_nil
  end
  
  it "should update the updated_at timestamp when the object is updated" do
    @box.save
    start = @box.updated_at
    @box.save
    @box.updated_at.should > start
  end
  
  after :all do
    Object.send(:remove_const, :Box)
  end
  
end
