require 'spec_helper'

describe Ripple::Observable do
  # require 'support/models/clock'
  # require 'support/models/clock_observer'

  before :each do
    @client   = Ripple.client
    @client.stub(:store_object => true)
    @clock    = Clock.new
    @observer = ClockObserver.instance
  end

  context "given a document is created" do
    it "should notify all observers twice" do
      Clock.should_receive(:notify_observers).exactly(6).times
      @clock.save
    end

    context "before creating the document" do
      it "should call Observer#before_create" do
        @observer.should_receive(:before_create)
        @clock.save
      end

      it "should call Observer#before_save" do
        @observer.should_receive(:before_save)
        @clock.save
      end

      it "should call Observer#before_validation" do
        @observer.should_receive(:before_validation)
        @clock.save
      end
    end

    context "after creating the document" do
      it "should call Observer#after_create" do
        @observer.should_receive(:after_create)
        @clock.save
      end

      it "should call Observer#after_save" do
        @observer.should_receive(:after_save)
        @clock.save
      end

      it "should call Observer#after_validation" do
        @observer.should_receive(:after_validation)
        @clock.save
      end
    end
  end

  context "given a document is updated" do
    before(:each) do
      @clock.stub!(:new?).and_return(false)
    end

    it "should notify all observers twice" do
      Clock.should_receive(:notify_observers).exactly(6).times
      @clock.save
    end

    context "before updating the document" do
      it "should call Observer#before_update" do
        @observer.should_receive(:before_update)
        @clock.save
      end

      it "should call Observer#before_save" do
        @observer.should_receive(:before_save)
        @clock.save
      end

      it "should call Observer#before_validation" do
        @observer.should_receive(:before_validation)
        @clock.save
      end
    end

    context "after updating the document" do
      it "should call Observer#after_update" do
        @observer.should_receive(:after_update)
        @clock.save
      end

      it "should call Observer#after_save" do
        @observer.should_receive(:after_save)
        @clock.save
      end

      it "should call Observer#after_validation" do
        @observer.should_receive(:after_validation)
        @clock.save
      end
    end
  end

  context "given a document is destroyed" do
    it "should notify all observers twice" do
      Clock.should_receive(:notify_observers).twice
      @clock.destroy
    end

    context "before destroying the document" do
      it "should call Observer#before_destroy" do
        @observer.should_receive(:before_destroy)
        @clock.destroy
      end
    end

    context "after destroy the document" do
      it "should call Observer#after_destroy" do
        @observer.should_receive(:after_destroy)
        @clock.destroy
      end
    end
  end
end
