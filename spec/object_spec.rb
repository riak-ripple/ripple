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
require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::RObject do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, "foo")
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
      file = File.open("#{File.dirname(__FILE__)}/fixtures/cat.jpg", "r")
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
        @object.serialize(2).should == "2"
        @object.serialize("Some text").should == '"Some text"'
        @object.serialize([1,2,3]).should == "[1,2,3]"
      end

      it "should deserialize a JSON blob" do
        @object.deserialize('{"foo":"bar"}').should == {"foo" => "bar"}
        @object.deserialize("2").should == 2
        @object.deserialize('"Some text"').should == "Some text"
        @object.deserialize('[1,2,3]').should == [1,2,3]
      end
    end

    describe "when the content type is an octet-stream" do
      before :each do
        @object.content_type = "application/octet-stream"
        @object.meta ||= {}
      end

      describe "if the ruby-serialization meta field is set to Marshal" do
        before :each do
          @object.meta['ruby-serialization'] = "Marshal"
          @payload = Marshal.dump({"foo" => "bar"})
        end

        it "should dump via Marshal" do
          @object.serialize({"foo" => "bar"}).should == @payload
        end

        it "should load from Marshal" do
          @object.deserialize(@payload).should == {"foo" => "bar"}
        end
      end

      describe "if the ruby-serialization meta field is not set to Marshal" do
        before :each do
          @object.meta.delete("ruby-serialization")
        end

        it "should dump to a string" do
          @object.serialize(2).should == "2"
          @object.serialize("foo").should == "foo"
        end

        it "should load the body unmodified" do
          @object.deserialize("foo").should == "foo"
        end
      end
    end
  end

  describe "loading data from the response" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should load the content type" do
      @object.load({:headers => {"content-type" => ["application/json"]}})
      @object.content_type.should == "application/json"
    end

    it "should load the body data" do
      @object.load({:headers => {"content-type" => ["application/json"]}, :body => '{"foo":"bar"}'})
      @object.data.should be_present
    end

    it "should deserialize the body data" do
      @object.should_receive(:deserialize).with("{}").and_return({})
      @object.load({:headers => {"content-type" => ["application/json"]}, :body => "{}"})
      @object.data.should == {}
    end

    it "should leave the object data unchanged if the response body is blank" do
      @object.data = "Original data"
      @object.load({:headers => {"content-type" => ["application/json"]}, :body => ""})
      @object.data.should == "Original data"
    end

    it "should load the vclock from the headers" do
      @object.load({:headers => {"content-type" => ["application/json"], 'x-riak-vclock' => ["somereallylongbase64string=="]}, :body => "{}"})
      @object.vclock.should == "somereallylongbase64string=="
    end

    it "should load links from the headers" do
      @object.load({:headers => {"content-type" => ["application/json"], "link" => ['</raw/bar>; rel="up"']}, :body => "{}"})
      @object.links.should have(1).item
      @object.links.first.url.should == "/raw/bar"
      @object.links.first.rel.should == "up"
    end

    it "should load the ETag from the headers" do
      @object.load({:headers => {"content-type" => ["application/json"], "etag" => ["32748nvas83572934"]}, :body => "{}"})
      @object.etag.should == "32748nvas83572934"
    end

    it "should load the modified date from the headers" do
      time = Time.now
      @object.load({:headers => {"content-type" => ["application/json"], "last-modified" => [time.httpdate]}, :body => "{}"})
      @object.last_modified.to_s.should == time.to_s # bah, times are not equivalent unless equal
    end

    it "should load meta information from the headers" do
      @object.load({:headers => {"content-type" => ["application/json"], "x-riak-meta-some-kind-of-robot" => ["for AWESOME"]}, :body => "{}"})
      @object.meta["some-kind-of-robot"].should == ["for AWESOME"]
    end

    it "should parse the location header into the key when present" do
      @object.load({:headers => {"content-type" => ["application/json"], "location" => ["/raw/foo/baz"]}})
      @object.key.should == "baz"
    end
  end

  describe "headers used for storing the object" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should include the content type" do
      @object.content_type = "application/json"
      @object.store_headers["Content-Type"].should == "application/json"
    end

    it "should include the vclock when present" do
      @object.vclock = "123445678990"
      @object.store_headers["X-Riak-Vclock"].should == "123445678990"
    end

    it "should exclude the vclock when nil" do
      @object.vclock = nil
      @object.store_headers.should_not have_key("X-Riak-Vclock")
    end

    describe "when links are defined" do
      before :each do
        @object.links = [Riak::Link.new("/raw/foo/baz", "next")]
      end

      it "should include a Link header with references to other objects" do
        @object.store_headers.should have_key("Link")
        @object.store_headers["Link"].should include('</raw/foo/baz>; riaktag="next"')
      end

      it "should exclude the 'up' link to the bucket from the header" do
        @object.links << Riak::Link.new("/raw/foo", "up")
        @object.store_headers.should have_key("Link")
        @object.store_headers["Link"].should_not include('riaktag="up"')
      end
    end

    it "should exclude the Link header when no links are present" do
      @object.links = []
      @object.store_headers.should_not have_key("Link")
    end

    describe "when meta fields are present" do
      before :each do
        @object.meta = {"some-kind-of-robot" => true, "powers" => "for awesome", "cold-ones" => 10}
      end

      it "should include X-Riak-Meta-* headers for each meta key" do
        @object.store_headers.should have_key("X-Riak-Meta-some-kind-of-robot")
        @object.store_headers.should have_key("X-Riak-Meta-cold-ones")
        @object.store_headers.should have_key("X-Riak-Meta-powers")
      end

      it "should turn non-string meta values into strings" do
        @object.store_headers["X-Riak-Meta-some-kind-of-robot"].should == "true"
        @object.store_headers["X-Riak-Meta-cold-ones"].should == "10"
      end

      it "should leave string meta values unchanged in the header" do
        @object.store_headers["X-Riak-Meta-powers"].should == "for awesome"
      end
    end
  end

  describe "headers used for reloading the object" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "should be blank when the etag and last_modified properties are blank" do
      @object.etag.should be_blank
      @object.last_modified.should be_blank
      @object.reload_headers.should be_blank
    end

    it "should include the If-None-Match key when the etag is present" do
      @object.etag = "etag!"
      @object.reload_headers['If-None-Match'].should == "etag!"
    end

    it "should include the If-Modified-Since header when the last_modified time is present" do
      time = Time.now
      @object.last_modified = time
      @object.reload_headers['If-Modified-Since'].should == time.httpdate
    end
  end

  describe "when storing the object normally" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
      @object = Riak::RObject.new(@bucket)
      @object.content_type = "text/plain"
      @object.data = "This is some text."
      @headers = @object.store_headers
    end

    it "should raise an error when the content_type is blank" do
      lambda { @object.content_type = nil; @object.store }.should raise_error(ArgumentError)
      lambda { @object.content_type = "   "; @object.store }.should raise_error(ArgumentError)
    end

    describe "when the object has no key" do
      it "should issue a POST request to the bucket, and update the object properties (returning the body by default)" do
        @http.should_receive(:post).with([200,204], "/raw/", "foo", {:returnbody => true}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}, :code => 204})
        @object.store
        @object.key.should == "somereallylongstring"
        @object.vclock.should == "areallylonghashvalue"
      end

      it "should include persistence-tuning parameters in the query string" do
        @http.should_receive(:post).with([200,204], "/raw/", "foo", {:dw => 2, :returnbody => true}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}, :code => 204})
        @object.store(:dw => 2)
      end
    end

    describe "when the object has a key" do
      before :each do
        @object.key = "bar"
      end

      it "should issue a PUT request to the bucket, and update the object properties (returning the body by default)" do
        @http.should_receive(:put).with([200,204], "/raw/", "foo/bar", {:returnbody => true}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}, :code => 204})
        @object.store
        @object.key.should == "somereallylongstring"
        @object.vclock.should == "areallylonghashvalue"
      end

      it "should include persistence-tuning parameters in the query string" do
        @http.should_receive(:put).with([200,204], "/raw/", "foo/bar", {:dw => 2, :returnbody => true}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}, :code => 204})
        @object.store(:dw => 2)
      end
    end
  end

  describe "when reloading the object" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
      @object = Riak::RObject.new(@bucket, "bar")
      @object.vclock = "somereallylongstring"
      @object.stub!(:reload_headers).and_return({})
    end

    it "should return without requesting if the key is blank" do
      @object.key = nil
      @http.should_not_receive(:get)
      @object.reload
    end

    it "should return without requesting if the vclock is blank" do
      @object.vclock = nil
      @http.should_not_receive(:get)
      @object.reload
    end

    it "should make the request if the key is present and the :force option is given" do
      @http.should_receive(:get).and_return({:headers => {}, :code => 304})
      @object.reload :force => true
    end

    it "should pass along the reload_headers" do
      @headers = {"If-None-Match" => "etag"}
      @object.should_receive(:reload_headers).and_return(@headers)
      @http.should_receive(:get).with([200,304], "/raw/", "foo", "bar", {}, @headers).and_return({:code => 304})
      @object.reload
    end

    it "should return without modifying the object if the response is 304 Not Modified" do
      @http.should_receive(:get).and_return({:code => 304})
      @object.should_not_receive(:load)
      @object.reload
    end

    it "should raise an exception when the response code is not 200 or 304" do
      @http.should_receive(:get).and_raise(Riak::FailedRequest.new(:get, 200, 500, {}, ''))
      @object.should_not_receive(:load)
      lambda { @object.reload }.should raise_error(Riak::FailedRequest)
    end
  end

  describe "walking from the object to linked objects" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
      @client.stub!(:bucket).and_return(@bucket)
      @object = Riak::RObject.new(@bucket, "bar")
      @body = File.read(File.join(File.dirname(__FILE__), "fixtures", "multipart-with-body.txt"))
    end

    it "should issue a GET request to the given walk spec" do
      @http.should_receive(:get).with(200, "/raw/", "foo", "bar", "_,next,1").and_return(:headers => {"content-type" => ["multipart/mixed; boundary=12345"]}, :body => "\n--12345\nContent-Type: multipart/mixed; boundary=09876\n\n--09876--\n\n--12345--\n")
      @object.walk(nil,"next",true)
    end

    it "should parse the results into arrays of objects" do
      @http.stub!(:get).and_return(:headers => {"content-type" => ["multipart/mixed; boundary=5EiMOjuGavQ2IbXAqsJPLLfJNlA"]}, :body => @body)
      results = @object.walk(nil,"next",true)
      results.should be_kind_of(Array)
      results.first.should be_kind_of(Array)
      obj = results.first.first
      obj.should be_kind_of(Riak::RObject)
      obj.content_type.should == "text/plain"
      obj.key.should == "baz"
      obj.bucket.should == @bucket
    end

    it "should assign the bucket for newly parsed objects" do
      @http.stub!(:get).and_return(:headers => {"content-type" => ["multipart/mixed; boundary=5EiMOjuGavQ2IbXAqsJPLLfJNlA"]}, :body => @body)
      @client.should_receive(:bucket).with("foo", :keys => false).and_return(@bucket)
      @object.walk(nil,"next",true)
    end
  end
end
