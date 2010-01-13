require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Object do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, "foo")
  end
  
  describe "creating an object from a response" do
    it "should create a Riak::Document for a JSON object" do
      Riak::Object.load(@bucket, "bar", {:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'}).should be_kind_of(Riak::Document)
    end

    it "should create a Riak::Document for a YAML object" do
      Riak::Object.load(@bucket, "bar", {:headers => {"content-type" => ["application/x-yaml"]}, :body => "---\nname: Riak\ncompany: Basho\n"}).should be_kind_of(Riak::Document)
    end
    
    it "should create a Riak::Binary for a binary type" do
      Riak::Object.load(@bucket, "bar", {:headers => {"content-type" => ["application/octet-stream"]}, :body => 'ASD#$*@)#$%&*Q)DA&@*#$*'}).should be_kind_of(Riak::Binary)
    end

    it "should create a bare Riak::Object if none of the subclasses match" do
      obj = Riak::Object.load(@bucket, "bar", {:headers => {"content-type" => ["text/richtext"]}, :body => 'This is my magnum opus.'})
      obj.should_not be_kind_of(Riak::Document)
      obj.should_not be_kind_of(Riak::Binary)
    end
  end

  describe "loading data from the response" do
    before :each do
      @object = Riak::Object.new(@bucket, "bar")
    end
    
    it "should load the content type" do
      @object.load({:headers => {"content-type" => ["application/json"]}})
      @object.content_type.should == "application/json"
    end

    it "should load the body data" do
      @object.load({:headers => {"content-type" => ["application/json"]}, :body => "{}"})
      @object.data.should == "{}"
    end

    it "should load the vclock from the headers" do
      @object.load({:headers => {"content-type" => ["application/json"], 'x-riak-vclock' => ["somereallylongbase64string=="]}, :body => "{}"})
      @object.vclock.should == "somereallylongbase64string=="
    end
    
    it "should load links from the headers"
    it "should load the ETag from the headers"
    it "should load the modified date from the headers"
    it "should load meta information from the headers"
  end
end
