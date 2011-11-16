require 'spec_helper'

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

    it "should initialize indexes to an empty hash with a Set for the default value" do
      @object = Riak::RObject.new(@bucket, "bar")
      @object.indexes.should be_kind_of(Hash)
      @object.indexes.should be_empty
      @object.indexes['foo_bin'].should be_kind_of(Set)
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

    it 'delegates #serialize to the appropriate serializer for the content type' do
      @object.content_type = 'text/plain'
      Riak::Serializers.should respond_to(:serialize).with(2).arguments
      Riak::Serializers.should_receive(:serialize).with('text/plain', "foo").and_return("serialized foo")
      @object.serialize("foo").should == "serialized foo"
    end

    it 'delegates #deserialize to the appropriate serializer for the content type' do
      @object.content_type = 'text/plain'
      Riak::Serializers.should respond_to(:deserialize).with(2).arguments
      Riak::Serializers.should_receive(:deserialize).with('text/plain', "foo").and_return("deserialized foo")
      @object.deserialize("foo").should == "deserialized foo"
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
          @object.data = { 'some' => 'data' }
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

        context 'for an IO-like object' do
          let(:io_object) { stub(:read => 'the io object') }

          it 'reads the object before deserializing it' do
            @object.should_receive(:deserialize).with('the io object').and_return('deserialized')
            @object.raw_data = io_object
            @object.data.should == 'deserialized'
          end

          it 'does not allow it to be assigned directly to data since it should be assigned to raw_data instead' do
            expect {
              @object.data = io_object
            }.to raise_error(ArgumentError)
          end
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
                                            "X-Riak-Meta"=>{"X-Riak-Meta-King-Of-Robots"=>"I"},
                                            "index" => {
                                              "email_bin" => ["sean@basho.com","seancribbs@gmail.com"],
                                              "rank_int" => 50
                                            }
                                          },
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

    it "should load and parse indexes" do
      @object.indexes.should have(2).items
      @object.indexes['email_bin'].should have(2).items
      @object.indexes['rank_int'].should have(1).item
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

    it 'should return [self] for siblings' do
      @object.siblings.should == [@object]
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
      @client.stub!(:backend).and_yield(@backend)
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
      @backend.should_receive(:store_object).with(@object, :returnbody => false, :w => 3, :dw => 2).and_return(true)
      @object.store(:returnbody => false, :w => 3, :dw => 2)
    end
  end

  describe "when reloading the object" do
    before :each do
      @backend = mock("Backend")
      @client.stub!(:backend).and_yield(@backend)
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
      @backend.should_receive(:reload_object).with(@object, {}).and_return(@object)
      @object.reload
    end

    it "should pass along the requested R quorum" do
      @backend.should_receive(:reload_object).with(@object, :r => 2).and_return(@object)
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
      @client.stub!(:http).and_yield(@http)
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
      @client.stub!(:backend).and_yield(@backend)
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should make a DELETE request to the Riak server and freeze the object" do
      @backend.should_receive(:delete_object).with(@bucket, "bar", {})
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

    it "should send the vector clock if present" do
      @object.vclock = "somevclock"
      @backend.should_receive(:delete_object).with(@bucket, "bar", {:vclock => "somevclock"})
      @object.delete
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

  describe "#inspect" do
    let(:object) { Riak::RObject.new(@bucket) }

    it "provides useful output even when the key is nil" do
      expect { object.inspect }.not_to raise_error
      object.inspect.should be_kind_of(String)
    end

    it 'uses the serializer output in inspect' do
      object.raw_data = { 'a' => 7 }
      object.content_type = 'inspect/type'
      Riak::Serializers['inspect/type'] = Object.new.tap do |o|
        def o.load(object); "serialize for inspect"; end
      end

      object.inspect.should =~ /serialize for inspect/
    end
  end

  describe '.on_conflict' do
    it 'adds the hook to the list of on conflict hooks' do
      hook_run = false
      described_class.on_conflict_hooks.should be_empty
      described_class.on_conflict { hook_run = true }
      described_class.on_conflict_hooks.size.should == 1
      described_class.on_conflict_hooks.first.call
      hook_run.should == true
    end
  end

  describe '#attempt_conflict_resolution' do
    let(:conflicted_robject) { Riak::RObject.new(@bucket, "conflicted") { |r| r.conflict = true } }
    let(:resolved_robject) { Riak::RObject.new(@bucket, "resolved") }
    let(:invoked_resolvers) { [] }
    let(:resolver_1) { lambda { |r| invoked_resolvers << :resolver_1; nil } }
    let(:resolver_2) { lambda { |r| invoked_resolvers << :resolver_2; :not_an_robject } }
    let(:resolver_3) { lambda { |r| invoked_resolvers << :resolver_3; r } }
    let(:resolver_4) { lambda { |r| invoked_resolvers << :resolver_4; resolved_robject } }

    before(:each) do
      described_class.on_conflict(&resolver_1)
      described_class.on_conflict(&resolver_2)
    end

    it 'calls each resolver until one of them returns an robject' do
      described_class.on_conflict(&resolver_3)
      described_class.on_conflict(&resolver_4)
      conflicted_robject.attempt_conflict_resolution
      invoked_resolvers.should == [:resolver_1, :resolver_2, :resolver_3]
    end

    it 'returns the robject returned by the last invoked resolver' do
      described_class.on_conflict(&resolver_4)
      conflicted_robject.attempt_conflict_resolution.should be(resolved_robject)
    end

    it 'allows the resolver to return the original robject' do
      described_class.on_conflict(&resolver_3)
      conflicted_robject.attempt_conflict_resolution.should be(conflicted_robject)
    end

    it 'returns the robject and does not call any resolvers if the robject is not in conflict' do
      resolved_robject.attempt_conflict_resolution.should be(resolved_robject)
      invoked_resolvers.should == []
    end

    it 'returns the original robject if none of the resolvers returns an robject' do
      conflicted_robject.attempt_conflict_resolution.should be(conflicted_robject)
      invoked_resolvers.should == [:resolver_1, :resolver_2]
    end
  end
end

