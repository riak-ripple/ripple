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

  describe "creating an object from a response" do
    it "should create a Riak::Document for a JSON object" do
      Riak::RObject.load(@bucket, "bar", {:headers => {"content-type" => ["application/json"]}, :body => '{"name":"Riak","company":"Basho"}'}).should be_kind_of(Riak::Document)
    end

    it "should create a Riak::Document for a YAML object" do
      Riak::RObject.load(@bucket, "bar", {:headers => {"content-type" => ["application/x-yaml"]}, :body => "---\nname: Riak\ncompany: Basho\n"}).should be_kind_of(Riak::Document)
    end

    it "should create a Riak::Binary for a binary type" do
      Riak::RObject.load(@bucket, "bar", {:headers => {"content-type" => ["application/octet-stream"]}, :body => 'ASD#$*@)#$%&*Q)DA&@*#$*'}).should be_kind_of(Riak::Binary)
    end

    it "should create a bare Riak::RObject if none of the subclasses match" do
      obj = Riak::RObject.load(@bucket, "bar", {:headers => {"content-type" => ["text/richtext"]}, :body => 'This is my magnum opus.'})
      obj.should_not be_kind_of(Riak::Document)
      obj.should_not be_kind_of(Riak::Binary)
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

    it "should not modify the data by default when deserializing" do
      @object.deserialize("foo").should == "foo"
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
      @object.load({:headers => {"content-type" => ["application/json"]}, :body => "{}"})
      @object.data.should == "{}"
    end

    it "should deserialize the body data" do
      @object.should_receive(:deserialize).with("{}").and_return("{}")
      @object.load({:headers => {"content-type" => ["application/json"]}, :body => "{}"})
      @object.data.should == "{}"
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
      @object.headers["Content-Type"].should == "application/json"
    end

    it "should include the vclock when present" do
      @object.vclock = "123445678990"
      @object.headers["X-Riak-Vclock"].should == "123445678990"
    end

    it "should exclude the vclock when nil" do
      @object.vclock = nil
      @object.headers.should_not have_key("X-Riak-Vclock")
    end

    describe "when links are defined" do
      before :each do
        @object.links = [Riak::Link.new("/raw/foo/baz", "next")]
      end

      it "should include a Link header with references to other objects" do
        @object.headers.should have_key("Link")
        @object.headers["Link"].should include('</raw/foo/baz>; riaktag="next"')
      end

      it "should exclude the 'up' link to the bucket from the header" do
        @object.links << Riak::Link.new("/raw/foo", "up")
        @object.headers.should have_key("Link")
        @object.headers["Link"].should_not include('riaktag="up"')
      end
    end

    it "should exclude the Link header when no links are present" do
      @object.links = []
      @object.headers.should_not have_key("Link")
    end

    describe "when meta fields are present" do
      before :each do
        @object.meta = {"some-kind-of-robot" => true, "powers" => "for awesome", "cold-ones" => 10}
      end

      it "should include X-Riak-Meta-* headers for each meta key" do
        @object.headers.should have_key("X-Riak-Meta-some-kind-of-robot")
        @object.headers.should have_key("X-Riak-Meta-cold-ones")
        @object.headers.should have_key("X-Riak-Meta-powers")
      end

      it "should turn non-string meta values into strings" do
        @object.headers["X-Riak-Meta-some-kind-of-robot"].should == "true"
        @object.headers["X-Riak-Meta-cold-ones"].should == "10"
      end

      it "should leave string meta values unchanged in the header" do
        @object.headers["X-Riak-Meta-powers"].should == "for awesome"
      end
    end
  end

  describe "when storing the object normally" do
    before :each do
      @http = mock("HTTPBackend")
      @client.stub!(:http).and_return(@http)
      @object = Riak::RObject.new(@bucket)
      @object.content_type = "text/plain"
      @object.data = "This is some text."
      @headers = @object.headers
    end

    describe "when the object has no key" do
      it "should issue a POST request to the bucket, and update the object properties" do
        @http.should_receive(:post).with(204, "foo", {}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}})
        @object.store
        @object.key.should == "somereallylongstring"
        @object.vclock.should == "areallylonghashvalue"
      end

      it "should include persistence-tuning parameters in the query string" do
        @http.should_receive(:post).with(204, "foo", {:dw => 2}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}})
        @object.store(:dw => 2)
      end
    end

    describe "when the object has a key" do
      before :each do
        @object.key = "bar"
      end

      it "should issue a PUT request to the bucket, and update the object properties" do
        @http.should_receive(:put).with(204, "foo/bar", {}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}})
        @object.store
        @object.key.should == "somereallylongstring"
        @object.vclock.should == "areallylonghashvalue"
      end

      it "should include persistence-tuning parameters in the query string" do
        @http.should_receive(:put).with(204, "foo/bar", {:dw => 2}, "This is some text.", @headers).and_return({:headers => {'location' => ["/raw/foo/somereallylongstring"], "x-riak-vclock" => ["areallylonghashvalue"]}})
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
      @http.should_receive(:get).and_return({:headers => {}})
      @object.reload :force => true
    end

    it "should add an If-None-Match header when an ETag is present" do
      @object.etag = "12345567890"
      @http.should_receive(:get).with(200, "foo", "bar", {}, hash_including('If-None-Match' => "12345567890")).and_return({:headers => {'etag' => ['0987654321']}})
      @object.reload
      @object.etag.should == '0987654321'
    end

    it "should add an If-Modified-Since header when the last modified date is present" do
      time = Time.now - 1000
      new_time = Time.now.httpdate
      @object.last_modified = time
      @http.should_receive(:get).with(200, "foo", "bar", {}, hash_including('If-Modified-Since' => time.httpdate)).and_return({:headers => {'last-modified' => [new_time]}})
      @object.reload
      @object.last_modified.httpdate.should == new_time
    end

    it "should return without modifying the object if the response is 304 Not Modified" do
      @http.should_receive(:get).and_raise(Riak::FailedRequest.new(:get, 200, 304, {}, ''))
      @object.should_not_receive(:load)
      @object.reload
    end

    it "should raise an exception when the response code is not 200 or 304" do
      @http.should_receive(:get).and_raise(Riak::FailedRequest.new(:get, 200, 500, {}, ''))
      @object.should_not_receive(:load)
      lambda { @object.reload }.should raise_error(Riak::FailedRequest)
    end
  end
end
