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
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Ripple do
  it "should have a client" do
    Ripple.client.should be_kind_of(Riak::Client)
  end

  it "should have a unique client per thread" do
    client = Ripple.client
    th = Thread.new { Ripple.client.should_not == client }
    th.join
  end

  it "should be configurable" do
    Ripple.should respond_to(:config)
  end

  it "should allow setting the client manually" do
    Ripple.should respond_to(:client=)
    client = Riak::Client.new(:port => 9000)
    Ripple.client = client
    Ripple.client.should == client
  end
  
  it "should reset the client when the configuration changes" do
    c = Ripple.client
    Ripple.config = {:port => 9000}
    Ripple.client.should_not == c
    Ripple.client.port.should == 9000
  end
  
  it "should raise No Such File or Directory when given a bad configuration file" do
    lambda { Ripple.load_config('not-here') }.should raise_error(Ripple::MissingConfiguration)
  end
  
  it "should pass an empty hash into configure if the configuration file is missing the key" do
    Ripple.should_receive(:config=).with({})
    Ripple.load_config(File.join(File.dirname(__FILE__), '..', 'fixtures', 'config.yml'), [:ripple, 'not-here'])
  end
  
  it "should select the configuration hash from the config keys provided" do
    Ripple.load_config(File.join(File.dirname(__FILE__), '..', 'fixtures', 'config.yml'), ['ripple_rails', 'development'])
    Ripple.client.port.should == 9001
    Ripple.client.host.should == '127.0.0.1'
  end
  
  it "should apply the configuration under the ripple key" do
    Ripple.load_config(File.join(File.dirname(__FILE__), '..', 'fixtures', 'config.yml'))
    Ripple.client.port.should == 9000
    Ripple.client.host.should == 'localhost'
  end
end
