# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::RObject do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, "foo")
  end

  describe "initialization" do
    it "should set the bucket" do
      @object = Riak::RObject.new(@bucket)
      @object.bucket.should == @bucket
    end

    it "should set the key" do
      @object = Riak::RObject.new(@bucket, "bar")
      @object.key.should == "bar"
    end

    it "should initialize the links to an empty set" do
      @object = Riak::RObject.new(@bucket, "bar")
      @object.links.should == Set.new
    end

    it "should initialize the meta to an empty hash" do
      @object = Riak::RObject.new(@bucket, "bar")
      @object.meta.should == {}
    end

    it "should yield itself to a given block" do
      Riak::RObject.new(@bucket, "bar") do |r|
        r.key.should == "bar"
      end
    end
  end

  describe "serialization" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should change the data into a string by default when serializing" do
      @object.serialize("foo").should == "foo"
      @object.serialize(2).should == "2"
    end

    it "should not change the data when it is an IO" do
      file = File.open("#{File.dirname(__FILE__)}/../fixtures/cat.jpg", "r")
      file.should_not_receive(:to_s)
      @object.serialize(file).should == file
    end

    it "should not modify the data by default when deserializing" do
      @object.deserialize("foo").should == "foo"
    end

    describe "when the content type is YAML" do
      before :each do
        @object.content_type = "text/x-yaml"
      end

      it "should serialize into a YAML stream" do
        @object.serialize({"foo" => "bar"}).should == "--- \nfoo: bar\n"
      end

      it "should deserialize a YAML stream" do
        @object.deserialize("--- \nfoo: bar\n").should == {"foo" => "bar"}
      end
    end

    describe "when the content type is JSON" do
      before :each do
        @object.content_type = "application/json"
      end

      it "should serialize into a JSON blob" do
        @object.serialize({"foo" => "bar"}).should == '{"foo":"bar"}'
        @object.serialize([1,2,3]).should == "[1,2,3]"
      end

      it "should deserialize a JSON blob" do
        @object.deserialize('{"foo":"bar"}').should == {"foo" => "bar"}
        @object.deserialize('[1,2,3]').should == [1,2,3]
      end
    end

    describe "when the content type is application/x-ruby-marshal" do
      before :each do
        @object.content_type = "application/x-ruby-marshal"
        @payload = Marshal.dump({"foo" => "bar"})
      end

      it "should dump via Marshal" do
        @object.serialize({"foo" => "bar"}).should == @payload
      end

      it "should load from Marshal" do
        @object.deserialize(@payload).should == {"foo" => "bar"}
      end
    end
  end

  describe "data access methods" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
      @object.content_type = "application/json"
    end

    describe "for raw data" do
      describe "when unserialized data was already provided" do
        before do
          @object.data = { :some => :data }
        end

        it "should reset unserialized forms when stored" do
          @object.raw_data = value = '{ "raw": "json" }'

          @object.raw_data.should == value
          @object.data.should == { "raw" => "json" }
        end

        it "should lazily serialize when read" do
          @object.raw_data.should == '{"some":"data"}'
        end
      end

      it "should not unnecessarily marshal/demarshal" do
        @object.should_not_receive(:serialize)
        @object.should_not_receive(:deserialize)
        @object.raw_data = value = "{not even valid json!}}"
        @object.raw_data.should == value
      end
    end

    describe "for unserialized data" do
      describe "when raw data was already provided" do
        before do
          @object.raw_data = '{"some":"data"}'
        end

        it "should reset previously stored raw data" do
          @object.data = value = { "new" => "data" }
          @object.raw_data.should == '{"new":"data"}'
          @object.data.should == value
        end

        it "should lazily deserialize when read" do
          @object.data.should == { "some" => "data" }
        end
      end

      it "should not unnecessarily marshal/demarshal" do
        @object.should_not_receive(:serialize)
        @object.should_not_receive(:deserialize)
        @object.data = value = { "some" => "data" }
        @object.data.should == value
      end
    end
  end


  describe "instantiating new object from a map reduce operation" do
    before :each do
      @client.stub!(:[]).and_return(@bucket)

      @sample_response = [
                          {"bucket"=>"users",
                            "key"=>"A2IbUQ2KEMbe4WGtdL97LoTi1DN%5B%28%5C%2F%29%5D",
                            "vclock"=> "a85hYGBgzmDKBVIsCfs+fc9gSN9wlA8q/hKosDpIOAsA",
                            "values"=> [
                                        {"metadata"=>
                                          {"Links"=>[["addresses", "A2cbUQ2KEMbeyWGtdz97LoTi1DN", "home_address"]],
                                            "X-Riak-VTag"=>"5bnavU3rrubcxLI8EvFXhB",
                                            "content-type"=>"application/json",
                                            "X-Riak-Last-Modified"=>"Mon, 12 Jul 2010 21:37:43 GMT",
                                            "X-Riak-Meta"=>{"X-Riak-Meta-King-Of-Robots"=>"I"}},
                                          "data"=>
                                          "{\"email\":\"mail@test.com\",\"_type\":\"User\"}"
                                        }
                                       ]
                          }
                         ]
      @object = Riak::RObject.load_from_mapreduce(@client,@sample_response).first
      @object.should be_kind_of(Riak::RObject)
    end

    it "should load the content type" do
      @object.content_type.should == "application/json"
    end

    it "should load the body data" do
      @object.data.should be_present
    end

    it "should deserialize the body data" do
      @object.data.should == {"email" => "mail@test.com", "_type" => "User"}
    end

    it "should set the vclock" do
      @object.vclock.should == "a85hYGBgzmDKBVIsCfs+fc9gSN9wlA8q/hKosDpIOAsA"
    end

    it "should load and parse links" do
      @object.links.should have(1).item
      @object.links.first.url.should == "/riak/addresses/A2cbUQ2KEMbeyWGtdz97LoTi1DN"
      @object.links.first.rel.should == "home_address"
    end

    it "should set the ETag" do
      @object.etag.should == "5bnavU3rrubcxLI8EvFXhB"
    end

    it "should set modified date" do
      @object.last_modified.to_i.should == Time.httpdate("Mon, 12 Jul 2010 21:37:43 GMT").to_i
    end

    it "should load meta information" do
      @object.meta["King-Of-Robots"].should == ["I"]
    end

    it "should set the key" do
      @object.key.should == "A2IbUQ2KEMbe4WGtdL97LoTi1DN[(\\/)]"
    end

    it "should not set conflict when there is none" do
      @object.conflict?.should be_false
    end

    describe "when there are multiple values in an object" do
      before :each do
        response = @sample_response.dup
        response[0]['values'] << {
          "metadata"=> {
            "Links"=>[],
            "X-Riak-VTag"=>"7jDZLdu0fIj2iRsjGD8qq8",
            "content-type"=>"application/json",
            "X-Riak-Last-Modified"=>"Mon, 14 Jul 2010 19:28:27 GMT",
            "X-Riak-Meta"=>[]
          },
          "data"=> "{\"email\":\"mail@domain.com\",\"_type\":\"User\"}"
        }
        @object = Riak::RObject.load_from_mapreduce( @client, response ).first
      end

      it "should expose siblings" do
        @object.should have(2).siblings
        @object.siblings[0].etag.should == "5bnavU3rrubcxLI8EvFXhB"
        @object.siblings[1].etag.should == "7jDZLdu0fIj2iRsjGD8qq8"
      end

      it "should be in conflict" do
        @object.data.should_not be_present
        @object.should be_conflict
      end

      it "should assign the same vclock to all the siblings" do
        @object.siblings.should be_all {|s| s.vclock == @object.vclock }
      end
    end
  end

  it "should not allow duplicate links" do
    @object = Riak::RObject.new(@bucket, "foo")
    @object.links << Riak::Link.new("/riak/foo/baz", "next")
    @object.links << Riak::Link.new("/riak/foo/baz", "next")
    @object.links.length.should == 1
  end

  describe "when storing the object normally" do
    before :each do
      @backend = mock("Backend")
      @client.stub!(:backend).and_return(@backend)
      @object = Riak::RObject.new(@bucket)
      @object.content_type = "text/plain"
      @object.data = "This is some text."
      # @headers = @object.store_headers
    end

    it "should raise an error when the content_type is blank" do
      lambda { @object.content_type = nil; @object.store }.should raise_error(ArgumentError)
      lambda { @object.content_type = "   "; @object.store }.should raise_error(ArgumentError)
    end

    it "should pass along quorum parameters and returnbody to the backend" do
      @backend.should_receive(:store_object).with(@object, false, 3, 2).and_return(true)
      @object.store(:returnbody => false, :w => 3, :dw => 2)
    end
  end

  describe "when reloading the object" do
    before :each do
      @backend = mock("Backend")
      @client.stub!(:backend).and_return(@backend)
      @object = Riak::RObject.new(@bucket, "bar")
      @object.vclock = "somereallylongstring"
    end

    it "should return without requesting if the key is blank" do
      @object.key = nil
      @backend.should_not_receive(:reload_object)
      @object.reload
    end

    it "should return without requesting if the vclock is blank" do
      @object.vclock = nil
      @backend.should_not_receive(:reload_object)
      @object.reload
    end

    it "should reload the object if the key is present" do
      @backend.should_receive(:reload_object).with(@object, nil).and_return(@object)
      @object.reload
    end

    it "should pass along the requested R quorum" do
      @backend.should_receive(:reload_object).with(@object, 2).and_return(@object)
      @object.reload :r => 2
    end
    
    it "should disable matching conditions if the key is present and the :force option is given" do
      @backend.should_receive(:reload_object) do |obj, _|
        obj.etag.should be_nil
        obj.last_modified.should be_nil
        obj
      end
      @object.reload :force => true
    end
  end

  describe "walking from the object to linked objects" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
      @client.stub!(:bucket).and_return(@bucket)
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should normalize the walk specs and submit the link-walking request to the HTTP backend" do
      @http.should_receive(:link_walk).with(@object, [instance_of(Riak::WalkSpec)]).and_return([])
      @object.walk(nil,"next",true).should == []
    end
  end

  describe "when deleting" do
    before :each do
      @backend = mock("Backend")
      @client.stub!(:backend).and_return(@backend)
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should make a DELETE request to the Riak server and freeze the object" do
      @backend.should_receive(:delete_object).with(@bucket, "bar", nil)
      @object.delete
      @object.should be_frozen
    end

    it "should do nothing when the key is blank" do
      @backend.should_not_receive(:delete_object)
      @object.key = nil
      @object.delete
    end

    it "should pass through a failed request exception" do
      @backend.should_receive(:delete_object).and_raise(Riak::HTTPFailedRequest.new(:delete, [204,404], 500, {}, ""))
      lambda { @object.delete }.should raise_error(Riak::FailedRequest)
    end
  end

  it "should not convert to link without a tag" do
    @object = Riak::RObject.new(@bucket, "bar")
    lambda { @object.to_link }.should raise_error
  end

  it "should convert to a link having the same url and a supplied tag" do
    @object = Riak::RObject.new(@bucket, "bar")
    @object.to_link("next").should == Riak::Link.new("/riak/foo/bar", "next")
  end

  it "should escape the bucket and key when converting to a link" do
    @object = Riak::RObject.new(@bucket, "deep/path")
    @bucket.should_receive(:name).and_return("bucket spaces")
    @object.to_link("bar").url.should == "/riak/bucket%20spaces/deep%2Fpath"
  end

  it "should provide a useful inspect output even when the key is nil" do
    @object = Riak::RObject.new(@bucket)
    lambda { @object.inspect }.should_not raise_error
    @object.inspect.should be_kind_of(String)
  end
end
