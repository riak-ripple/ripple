require 'spec_helper'
require 'riak/test_server'

describe Riak::TestServer do
  subject { $test_server }
  let(:app_config) { (subject.etc + 'app.config').read }

  it "should add the test backends to the code path" do
    erl_src = File.expand_path("../../../../erl_src", __FILE__)
    subject.env[:riak_kv][:add_paths].should include(erl_src)
    app_config.should match(/\{add_paths, \[.*#{erl_src.inspect}.*\]\}/)
  end

  it "should use the KV test backend" do
    subject.kv_backend.should == :riak_kv_test_backend
    subject.env[:riak_kv][:storage_backend].should == :riak_kv_test_backend
    app_config.should include("{storage_backend, riak_kv_test_backend}")
  end

  it "should use the Search test backend" do
    subject.search_backend.should == :riak_search_test_backend
    subject.env[:riak_search][:search_backend].should == :riak_search_test_backend
    app_config.should include("{search_backend, riak_search_test_backend}")
  end

  it "should clear stored data" do
    # TODO: use $test_server.to_host when client/host split is finished.
    client = Riak::Client.new(:http_port => subject.http_port)
    obj = client['test_bucket'].new("test_item")
    obj.data = {"data" => "testing"}
    obj.store # rescue nil

    subject.drop
    expect {
      client['test_bucket']['test_item']
    }.to raise_error(Riak::FailedRequest)
  end
end
