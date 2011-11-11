require 'spec_helper'

describe "Protocol Buffers" do
  before do
    @pbc_port ||= $test_server.pb_port
    @client = Riak::Client.new(:pb_port => @pbc_port, :protocol => "pbc")
  end

  [:BeefcakeProtobuffsBackend].each do |klass|
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
end
