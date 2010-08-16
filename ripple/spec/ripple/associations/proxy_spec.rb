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
require File.expand_path("../../../spec_helper", __FILE__)

describe Ripple::Associations::Proxy do
  require 'support/associations/proxies'

  before :each do
    @owner = mock('owner')
    @owner.stub!(:new?).and_return(false)
    @association = mock('association')
    @association.stub!(:options).and_return({:extend => []})

    @proxy = FakeProxy.new(@owner, @association)
    @nil_proxy = FakeNilProxy.new(@owner, @association)
    @blank_proxy = FakeBlankProxy.new(@owner, @association)
  end

  it "should pretend to be the target class" do
    @proxy.should be_kind_of(Array)
  end

  it "should set the target to nil when reset" do
    @proxy.reset
    @proxy.target.should be_nil
  end

  describe "delegation" do
    it "should inspect the target" do
      @proxy.inspect.should == "[1, 2]"
    end

    it "should respond to the same methods as the target" do
      [:each, :size].each do |m|
        @proxy.should respond_to(m)
      end
      @proxy.should_not respond_to(:gsub)
    end

    it "should send to the proxy if it responds to the method" do
      @proxy.send(:reset)
      @proxy.target.should be_nil
    end

    it "should send to the target if target responds to the method" do
      @proxy.send(:size).should == 2
    end

    it "should send resulting in a method missing if neither the proxy nor the target respond to the method" do
      lambda { @proxy.send(:explode) }.should raise_error(NoMethodError)
    end
  end

  describe "when target is nil" do
    subject { @nil_proxy }
    it { should be_nil }
    it { should be_blank }
    it { should_not be_present }
  end

  describe "when the target is blank" do
    subject { @blank_proxy }
    it { should_not be_nil }
    it { should be_blank }
    it { should_not be_present }
  end
end