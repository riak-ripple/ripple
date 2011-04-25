require File.expand_path("../../spec_helper", File.dirname(__FILE__))

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
end
