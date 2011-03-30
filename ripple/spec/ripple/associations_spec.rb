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

describe Ripple::Associations do
  require 'support/models/invoice'
  require 'support/models/customer'
  require 'support/models/note'

  it "should provide access to the associations hash" do
    Invoice.should respond_to(:associations)
    Invoice.associations.should be_kind_of(Hash)
  end

  it "should collect the embedded associations" do
    Invoice.embedded_associations.should == Array(Invoice.associations[:note])
  end

  it "should copy associations to a subclass" do
    Invoice.associations[:foo] = "bar"
    class SubInvoice < Invoice; end
    SubInvoice.associations[:foo].should == "bar"
  end

  describe "when adding a :many association" do
    it "should add accessor and mutator methods" do
      Invoice.many :items
      Invoice.instance_methods.map(&:to_sym).should include(:items)
      Invoice.instance_methods.map(&:to_sym).should include(:items=)
    end
  end

  describe "when adding a :one association" do
    it "should add accessor, mutator, and query methods" do
      Invoice.one :payee
      Invoice.instance_methods.map(&:to_sym).should include(:payee)
      Invoice.instance_methods.map(&:to_sym).should include(:payee=)
      Invoice.instance_methods.map(&:to_sym).should include(:payee?)
    end
  end

  after do
    Invoice.associations.delete(:foo)
    Invoice.associations.delete(:items)
    SubInvoice.associations.delete(:foo) if defined?(SubInvoice)
    Invoice.associations.delete(:payee)
  end
end

describe Ripple::Association do
  it "should initialize with a type and name" do
    lambda { Ripple::Association.new(:many, :pages) }.should_not raise_error
  end

  describe "determining the class name" do
    it "should default to the camelized class name on :one relationships" do
      @association = Ripple::Association.new(:one, :page)
      @association.class_name.should == "Page"
    end

    it "should default to the singularized camelized class name on :many relationships" do
      @association = Ripple::Association.new(:many, :pages)
      @association.class_name.should == "Page"
    end

    it "should use the :class_name option when given" do
      @association = Ripple::Association.new(:many, :pages, :class_name => "Note")
      @association.class_name.should == "Note"
    end
  end

  describe "determining the target class" do
    require 'support/models/tree'

    it "should default to the constantized class name" do
      @association = Ripple::Association.new(:one, :t, :class_name => "Trunk")
      @association.klass.should == Trunk
    end

    it "should be determined by the derived class name" do
      @association = Ripple::Association.new(:many, :branches)
      @association.klass.should == Branch
    end

    it "should use the :class option when given" do
      @association = Ripple::Association.new(:many, :pages, :class => Leaf)
      @association.klass.should == Leaf
    end
  end

  it "should be many when type is :many" do
    Ripple::Association.new(:many, :pages).should be_many
  end

  it "should be one when type is :one" do
    Ripple::Association.new(:one, :pages).should be_one
  end

  it "should determine an instance variable based on the name" do
    Ripple::Association.new(:many, :pages).ivar.should == "@_pages"
  end
end
