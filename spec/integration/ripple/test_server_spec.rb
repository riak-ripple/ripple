require 'spec_helper'
require 'ripple/test_server'

describe Ripple::TestServer do
  around do |example|
    old_config = Ripple.config
    example.call
    Ripple.config = old_config
  end
  
  it "should respect the add_paths setting in Ripple.config [#256]" do
    config = YAML.load_file(File.expand_path("../../../support/test_server.yml", __FILE__))
    Ripple.config = {
      :root => config['root'],
      :source => config['source'],
      :min_port => (config['min_port'] || 15000) + 1000,
      :env => { :riak_kv => {:add_paths => ["app/mapreduce/erlang"]} }
    }
    Ripple::TestServer.instance.env[:riak_kv][:add_paths].should include("app/mapreduce/erlang")
  end
end
