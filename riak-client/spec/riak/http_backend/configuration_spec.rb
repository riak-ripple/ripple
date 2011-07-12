require 'spec_helper'

describe Riak::Client::HTTPBackend::Configuration do
  before do
    @client = Riak::Client.new
    @backend = Riak::Client::HTTPBackend.new(@client)
  end

  it "should memoize the server config" do
    @backend.should_receive(:get).with(200, "/", {}, {}).once.and_return(:headers => {'link' => ['</riak>; rel="riak_kv_wm_link_walker",</mapred>; rel="riak_kv_wm_mapred",</ping>; rel="riak_kv_wm_ping",</riak>; rel="riak_kv_wm_raw",</stats>; rel="riak_kv_wm_stats"']})
    @backend.send(:riak_kv_wm_link_walker).should == "/riak"
    @backend.send(:riak_kv_wm_raw).should == "/riak"
  end

  {
    :riak_kv_wm_raw => :prefix,
    :riak_kv_wm_link_walker => :prefix,
    :riak_kv_wm_mapred => :mapred
  }.each do |resource, alternate|
    it "should detect the #{resource} resource from the configuration URL" do
      @backend.should_receive(:get).with(200, "/", {}, {}).and_return(:headers => {'link' => [%Q{</path>; rel="#{resource}"}]})
      @backend.send(resource).should == "/path"
    end
    it "should fallback to client.#{alternate} if the #{resource} resource is not found" do
      @backend.should_receive(:get).with(200, "/", {}, {}).and_return(:headers => {'link' => ['</>; rel="top"']})
      @backend.send(resource).should == @client.send(alternate)
    end
    it "should fallback to client.#{alternate} if request fails" do
      @backend.should_receive(:get).with(200, "/", {}, {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, ""))
      @backend.send(resource).should == @client.send(alternate)
    end
  end

  {
    :riak_kv_wm_ping => "/ping",
    :riak_kv_wm_stats => "/stats"
  }.each do |resource, default|
    it "should detect the #{resource} resource from the configuration URL" do
      @backend.should_receive(:get).with(200, "/", {}, {}).and_return(:headers => {'link' => [%Q{</path>; rel="#{resource}"}]})
      @backend.send(resource).should == "/path"
    end
    it "should fallback to #{default.inspect} if the #{resource} resource is not found" do
      @backend.should_receive(:get).with(200, "/", {}, {}).and_return(:headers => {'link' => ['</>; rel="top"']})
      @backend.send(resource).should == default
    end
    it "should fallback to #{default.inspect} if request fails" do
      @backend.should_receive(:get).with(200, "/", {}, {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, ""))
      @backend.send(resource).should == default
    end
  end
end
