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

describe Ripple::Document do
  require 'support/models/page'

  it "should add bucket access methods to classes when included" do
    (class << Page; self; end).included_modules.should include(Ripple::Document::BucketAccess)
    Page.should respond_to(:bucket_name)
    Page.should respond_to(:bucket)
    Page.should respond_to(:bucket_name=)
  end

  it "should not be embeddable" do
    Page.should_not be_embeddable
  end

  describe "equivalence" do
    before do
      class Homepage < Page; end
      class ErrorPage; include Ripple::Document; self.bucket_name = "pages"; end
      @doc = Page.new
      @doc2 = Page.new
      @sub = Homepage.new
      @error = ErrorPage.new
      [@doc,@doc2,@sub,@error].each {|d| d.key = "root"; d.stub!(:new?).and_return(false) }
    end

    it "should be equal if the same object" do
      @doc.should == @doc
    end

    it "should be equal if instance of same class and key" do
      @doc.should == @doc2
      @doc.should == @sub
    end

    it "should be equal if of the same bucket and key" do
      @doc.should == @error
    end

    it "should not be equal if new record" do
      @doc2.stub!(:new?).and_return(true)
      @doc.should_not == @doc2
    end
  end

  describe "ActiveModel compatibility" do
    include ActiveModel::Lint::Tests

    before :each do
      @model = Page.new
    end

    def assert(value, message="")
      value.should be
    end

    def assert_kind_of(klass, value)
      value.should be_kind_of(klass)
    end

    ActiveModel::Lint::Tests.instance_methods.grep(/^test/).each do |m|
      it "#{m}" do
        send(m)
      end
    end
  end
end
