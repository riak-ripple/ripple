require 'spec_helper'

describe Ripple::Document::Finders do
  # require 'support/models/box'
  # require 'support/models/cardboard_box'

  before :each do
    @client = Ripple.client
    @bucket = Ripple.client.bucket("boxes")
    @plain = Riak::RObject.new(@bucket, "square"){|o| o.content_type = "application/json"; o.raw_data = '{"shape":"square"}'}
    @cb = Riak::RObject.new(@bucket, "rectangle"){|o| o.content_type = "application/json"; o.raw_data = '{"shape":"rectangle"}'}
  end

  it "should return nil if no keys are passed to find" do
    Box.find().should be_nil
  end

  it "should return nil if no valid keys are passed to find" do
    Box.find(nil).should be_nil
    Box.find("").should be_nil
  end

  it "should raise Ripple::DocumentNotFound if an empty array is passed to find!" do
    lambda { Box.find!() }.should raise_error(Ripple::DocumentNotFound, "Couldn't find document without a key")
  end

  describe "finding single documents" do
    before do
      @bucket.stub!(:get).with("square", {}).and_return(@plain)
    end

    it "should find a single document by key and assign its attributes" do
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      box = Box.find("square")
      box.should be_kind_of(Box)
      box.shape.should == "square"
      box.key.should == "square"
      box.instance_variable_get(:@robject).should_not be_nil
      box.should_not be_new_record
    end

    it "should have no changes after find" do
      box = Box.find("square")
      box.changes.should == {}
    end

    it "should find the first document using the first key with the bucket's keys" do
      box  = Box.new
      keys = ['some_boxes_key']
      Box.stub!(:find).and_return(box)
      @bucket.stub!(:keys).and_return(keys)
      @bucket.should_receive(:keys)
      keys.should_receive(:first)
      Box.first.should == box
    end

    it "should use find! when using first!" do
      box = Box.new
      Box.stub!(:find!).and_return(box)
      @bucket.stub!(:keys).and_return(['key'])
      Box.first!.should == box
    end

    it "should not raise an exception when finding an existing document with find!" do
      lambda { Box.find!("square") }.should_not raise_error(Ripple::DocumentNotFound)
    end

    it "should put properties we don't know about into the attributes" do
      @plain.raw_data = '{"non_existent_property":"some_value"}'
      box = Box.find("square")
      box[:non_existent_property].should == "some_value"
      box.should_not respond_to(:non_existent_property)
    end

    it "should return the document when calling find!" do
      box = Box.find!("square")
      box.should be_kind_of(Box)
    end

    it "should return nil when no object exists at that key" do
      @bucket.should_receive(:get).with("square", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      box = Box.find("square")
      box.should be_nil
    end

    it "should raise DocumentNotFound when using find! if no object exists at that key" do
      @bucket.should_receive(:get).with("square", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      lambda { Box.find!("square") }.should raise_error(Ripple::DocumentNotFound, "Couldn't find document with key: square")
    end

    it "should re-raise the failed request exception if not a 404" do
      @bucket.should_receive(:get).with("square", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 500, {}, "500 internal server error"))
      lambda { Box.find("square") }.should raise_error(Riak::FailedRequest)
    end

    it "should handle a key with a nil value" do
      @plain.raw_data = nil
      @plain.data = nil
      box = Box.find("square")
      box.should be_kind_of(Box)
      box.key.should == "square"
    end

    it 'initializes the document with no changed attributes' do
      box = Box.find("square")
      box.should_not be_changed
      box.changes.should be_empty
    end
  end

  describe "finding multiple documents when given a splat of keys" do
    it "should find multiple documents by the keys" do
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_return(@cb)
      boxes = Box.find("square", "rectangle")
      boxes.should have(2).items
      boxes.first.shape.should == "square"
      boxes.last.shape.should == "rectangle"
    end

    describe "when using find with missing keys" do
      before :each do
        @bucket.should_receive(:get).with("square", {}).and_return(@plain)
        @bucket.should_receive(:get).with("rectangle", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      end

      it "should return nil for documents that no longer exist" do
        boxes = Box.find("square", "rectangle")
        boxes.should have(2).items
        boxes.first.shape.should == "square"
        boxes.last.should be_nil
      end

      it "should raise Ripple::DocumentNotFound when calling find! if some of the documents do not exist" do
        lambda { Box.find!("square", "rectangle") }.should raise_error(Ripple::DocumentNotFound, "Couldn't find documents with keys: rectangle")
      end
    end
  end

  describe "finding multiple documents when given an array" do
    it "should find multiple documents by the keys" do
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_return(@cb)
      boxes = Box.find(["square", "rectangle"])
      boxes.should have(2).items
      boxes.first.shape.should == "square"
      boxes.last.shape.should == "rectangle"
    end

    it "should return an array of docs when given an array of one key" do
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      boxes = Box.find(["square"])
      boxes.should have(1).items
      boxes.first.shape.should == "square"
    end

    it "should return an empty array when given an empty array" do
      Box.find([ ]).should == []
    end

    describe "when using find with missing keys" do
      before :each do
        @bucket.should_receive(:get).with("square", {}).and_return(@plain)
        @bucket.should_receive(:get).with("rectangle", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      end

      it "should return nil for documents that no longer exist" do
        boxes = Box.find(["square", "rectangle"])
        boxes.should have(2).items
        boxes.first.shape.should == "square"
        boxes.last.should be_nil
      end
    end
  end

  describe "listings all documents in the bucket" do
    it "should load all objects in the bucket" do
      @bucket.should_receive(:keys).and_return(["square", "rectangle"])
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_return(@cb)
      boxes = Box.list
      boxes.should have(2).items
      boxes.first.shape.should == "square"
      boxes.last.shape.should == "rectangle"
    end

    it "should exclude objects that are not found" do
      @bucket.should_receive(:keys).and_return(["square", "rectangle"])
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      boxes = Box.list
      boxes.should have(1).item
      boxes.first.shape.should == "square"
    end

    it "should yield found objects to the passed block, excluding missing objects, and return an empty array" do
      @bucket.should_receive(:keys).and_yield(["square"]).and_yield(["rectangle"])
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      @block = mock()
      @block.should_receive(:ping).once
      Box.list do |box|
        @block.ping
        ["square", "rectangle"].should include(box.shape)
      end.should == []
    end
  end

  describe "single-bucket inheritance" do
    it "should instantiate as the proper type if defined in the document" do
      @cb.raw_data = '{"shape":"rectangle", "_type":"CardboardBox"}'
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_return(@cb)
      boxes = Box.find("square", "rectangle")
      boxes.should have(2).items
      boxes.first.class.should == Box
      boxes.last.should be_kind_of(CardboardBox)
    end
  end
end
