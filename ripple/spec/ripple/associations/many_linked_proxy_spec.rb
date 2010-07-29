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

describe Ripple::Associations::ManyLinkedProxy do
  require 'support/models/tasks'

  before :each do
    @person = Person.new {|p| p.key = "riak-user" }
    @task = Task.new {|t| t.key = "one" }
    @other_task = Task.new {|t| t.key = "two" }
    [@person, @task, @other_task].each do |doc|
      doc.stub!(:new?).and_return(false)
    end
  end

  it "should be empty before any associated documents are set" do
    @person.tasks.should be_empty
  end

  it "should accept an array of documents" do
    @person.tasks = [@task]
  end

  it "should set the links on the RObject when assigning" do
    @person.tasks = [@task]
    @person.robject.links.should include(@task.robject.to_link("tasks"))
  end

  it "should return the assigned documents when assigning" do
    t = (@person.tasks = [@task])
    t.should == [@task]
  end

  it "should save unsaved documents when assigning" do
    @task.should_receive(:new?).and_return(true)
    @task.should_receive(:save).and_return(true)
    @person.tasks = [@task]
  end

  it "should link-walk to the associated documents when accessing" do
    @person.robject.links << @task.robject.to_link("tasks")
    @person.robject.should_receive(:walk).with(Riak::WalkSpec.new(:bucket => "tasks", :tag => "tasks")).and_return([])
    @person.tasks.should == []
  end

  it "should replace associated documents with a new set" do
    @person.tasks = [@task]
    @person.tasks = [@other_task]
    @person.tasks.should == [@other_task]
  end

  it "should be able to append documents to the associated set" do
    @person.tasks << @task
    @person.tasks << @other_task
    @person.should have(2).tasks
  end

  it "should be able to chain calls to adding documents" do
    @person.tasks << @task << @other_task
    @person.should have(2).tasks
  end

  it "should set the links on the RObject when appending" do
    @person.tasks << @task << @other_task
    [@task, @other_task].each do |t|
      @person.robject.links.should include(t.robject.to_link("tasks"))
    end
  end

  it "should be able to count the associated documents" do
    @person.tasks << @task
    @person.tasks.count.should == 1
    @person.tasks << @other_task
    @person.tasks.count.should == 2
  end

  # it "should be able to build a new associated document" do
  #   pending "Need unsaved document support"
  # end

  it "should return an array from to_ary" do
    @person.tasks << @task
    @person.tasks.to_ary.should == [@task]
  end

  it "should refuse assigning a collection of the wrong type" do
    lambda { @person.tasks = nil }.should raise_error
    lambda { @person.tasks = @task }.should raise_error
    lambda { @person.tasks = [@person] }.should raise_error
  end
end
