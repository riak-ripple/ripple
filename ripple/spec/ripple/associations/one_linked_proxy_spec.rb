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

describe Ripple::Associations::OneLinkedProxy do
  require 'support/models/tasks'
  require 'support/models/family'

  before :each do
    @person = Person.new {|p| p.key = "riak-user" }
    @profile = Profile.new {|t| t.key = "one" }
    @other_profile = Profile.new {|t| t.key = "two" }
    [@person, @profile, @other_profile].each do |doc|
      doc.stub!(:new?).and_return(false)
    end
  end

  it "should be blank before the associated document is set" do
    @person.profile.should_not be_present
  end

  it "should accept a single document" do
    lambda { @person.profile = @profile }.should_not raise_error
  end

  it "should set the link on the RObject when assigning" do
    @person.profile = @profile
    @person.robject.links.should include(@profile.robject.to_link("profile"))
  end

  it "should return the assigned document when assigning" do
    ret = (@person.profile = @profile)
    ret.should == @profile
  end

  it "should save the new document when assigning" do
    @profile.should_receive(:new?).and_return(true)
    @profile.should_receive(:save).and_return(true)
    @person.profile = @profile
  end

  it "should link-walk to the associated document when accessing" do
    @person.robject.links << @profile.robject.to_link("profile")
    @person.robject.should_receive(:walk).with(Riak::WalkSpec.new(:bucket => "profiles", :tag => "profile")).and_return([[@profile.robject]])
    @person.profile.should be_present
  end

  it "should return nil immediately if the association link is missing" do
    @person.robject.links.should be_empty
    @person.profile.should be_nil
  end

  it "should replace associated document with a new one" do
    @person.profile = @profile
    @person.profile = @other_profile
    @person.profile.should == @other_profile
  end

  it "replaces the associated document with the target of the proxy" do
    @other_person = Person.new {|p| p.key = "another-riak-user" }
    @other_person.profile = @other_profile

    @person.profile = @other_person.profile
    @person.profile.should == @other_profile
  end

  it "refuses assigning a proxy if its target is the wrong type" do
    parent = Parent.new
    parent.child = Child.new

    lambda { @person.profile = parent.child }.should raise_error
  end

  # it "should be able to build a new associated document" do
  #   @person.profile.build
  # end

  it "should refuse assigning a document of the wrong type" do
    lambda { @person.profile = @person }.should raise_error
  end
end
