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

    it "should be == and eql? if the same object, and have the same hash key" do
      @doc.should == @doc
      @doc.should eql(@doc)
      @doc.hash.should == @doc.hash
    end

    it "should be == and eql? and have the same hash key if instance of same class and key" do
      @doc.should == @doc2
      @doc2.should == @doc
      @doc.should eql(@doc2)
      @doc2.should eql(@doc)
      @doc.hash.should == @doc2.hash
    end

    it "should be == but not eql? and have different hash keys if they have the same key but one is a subclass of the other" do
      @doc.should == @sub
      @sub.should == @doc

      @doc.should_not eql(@sub)
      @sub.should_not eql(@doc)

      @doc.hash.should_not == @sub.hash
    end

    it "should be == but not eql? and have different hash keys if of the same bucket and key" do
      @doc.should == @error
      @error.should == @doc

      @doc.should_not eql(@error)
      @error.should_not eql(@doc)

      @doc.hash.should_not == @error.hash
      @error.hash.should_not == @doc.hash
    end

    it "should not be == or eql? or have the same hash key if new record" do
      @doc2.stub!(:new?).and_return(true)
      @doc.should_not == @doc2
      @doc2.should_not == @doc

      @doc.should_not eql(@doc2)
      @doc2.should_not eql(@doc)

      @doc.hash.should_not == @doc2.hash
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
