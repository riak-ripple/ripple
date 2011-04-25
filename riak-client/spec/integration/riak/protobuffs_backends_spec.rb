require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe "Protocol Buffers" do
  before :all do
    if $test_server
      @pbc_port = 9002
      $test_server.start
    end
  end

  before do
    @pbc_port ||= 8087
    @client = Riak::Client.new(:pb_port => @pbc_port, :protocol => "pbc")
  end

  after do
    $test_server.recycle if $test_server.started?
  end

  [:BeefcakeProtobuffsBackend].each do |klass|
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
