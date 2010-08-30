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
require File.expand_path("../../spec_helper", __FILE__)
require 'ripple/session_store'

describe "Ripple::SessionStore" do
  include RSpec::Rails::RequestExampleGroup
  include Ripple::SessionTest
  hooks[:before][:each].pop # Remove the router crap
  before do
    routes = ActionDispatch::Routing::RouteSet.new.draw do
      match ':action', :to => ::Ripple::SessionStoreTest::TestController
    end

    @app = build_app(routes) do |middleware|
      middleware.use Ripple::SessionStore, :key => '_session_id'
      middleware.delete "ActionDispatch::ShowExceptions"
    end
  end

  it "should set and get a session value" do
    get '/set_session_value'
    puts response.inspect
    cookies['_session_id'].should be

    get '/get_session_value'
    response.should be_success
    'foo: "bar"'.should == response.body
  end
  
  it "should get nothing from a new session"
  it "should get an empty session after reset"
  it "should not create a session unless writing to it"
  it "should set a value in the new session after reset"
  it "should get the session id when the session exists"
  it "should deserialize an unloaded class"
  it "should not send the session cookie again if the ID already exists"
  it "should prevent session fixation"
end

