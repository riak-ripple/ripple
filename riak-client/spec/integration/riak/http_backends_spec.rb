require 'spec_helper'

describe "HTTP" do
  before :all do
    if $test_server
      @web_port = 9000
      $test_server.start
    end
  end

  before do
    @web_port ||= 8098
    @client = Riak::Client.new(:http_port => @web_port)
  end

  after do
    $test_server.recycle if $test_server.started?
  end

  [:ExconBackend, :NetHTTPBackend].each do |klass|
    bklass = Riak::Client.const_get(klass)
    if bklass.configured?
      describe klass.to_s do
        before do
          @backend = bklass.new(@client)
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
    subject { Riak::Client::NetHTTPBackend.new(@client) }
    let(:file) { File.open(__FILE__) }
    let(:sized) { Reader.new(["foo", "bar", "baz"]) }
    let(:sizeless) { SizelessReader.new(["foo", "bar", "baz"]) }
    it "should set the content-length or transfer-encoding properly on IO uploads" do
      lambda { subject.put(204, "/riak/nethttp", "test-file", file, {"Content-Type" => "text/plain"}) }.should_not raise_error
      lambda { subject.put(204, "/riak/nethttp", "test-sized", sized, {"Content-Type" => "text/plain"}) }.should_not raise_error
      lambda { subject.put(204, "/riak/nethttp", "test-file", sizeless, {"Content-Type" => "text/plain"}) }.should_not raise_error
    end
  end
end
