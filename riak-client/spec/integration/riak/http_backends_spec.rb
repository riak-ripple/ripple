require 'spec_helper'

describe "HTTP" do
  before do
    @web_port = $test_server.http_port
    @client = Riak::Client.new(:http_port => @web_port)
  end

  [:ExconBackend, :NetHTTPBackend].each do |klass|
    bklass = Riak::Client.const_get(klass)
    if bklass.configured?
      describe klass.to_s do
        before do
          @backend = bklass.new(@client, @client.node)
        end

        it_should_behave_like "Unified backend API"
      end
    end
  end

  class Reader < Array
    def read(*args)
      shift
    end

    def size
      join.size
    end
  end

  class SizelessReader < Reader
    undef :size
  end

  describe 'NetHTTPBackend' do
    subject { Riak::Client::NetHTTPBackend.new(@client, @client.node) }
    let(:file) { File.open(__FILE__) }
    let(:sized) { Reader.new(["foo", "bar", "baz"]) }
    let(:sizeless) { SizelessReader.new(["foo", "bar", "baz"]) }
    it "should set the content-length or transfer-encoding properly on IO uploads" do
      lambda { subject.put(204, subject.object_path('nethttp', 'test-file'), file, {"Content-Type" => "text/plain"}) }.should_not raise_error
      lambda { subject.put(204, subject.object_path('nethttp', 'test-sized'), sized, {"Content-Type" => "text/plain"}) }.should_not raise_error
      lambda { subject.put(204, subject.object_path('nethttp', 'test-sizeless'), sizeless, {"Content-Type" => "text/plain"}) }.should_not raise_error
    end
  end
end
