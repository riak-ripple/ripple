require File.expand_path("../../spec_helper", __FILE__)

describe Ripple::Callbacks do
  require 'support/models/box'

  it "should add create, update, save, and destroy callback declarations" do
    [:save, :create, :update, :destroy].each do |event|
      Box.private_instance_methods.map(&:to_s).should include("_run_#{event}_callbacks")
      [:before, :after, :around].each do |time|
        Box.should respond_to("#{time}_#{event}")
      end
    end
  end

  it "should validate callback declarations" do
    Box.private_instance_methods.map(&:to_s).should include("_run_validation_callbacks")
    Box.should respond_to("before_validation")
    Box.should respond_to("after_validation")
  end

  describe "invoking callbacks" do
    before :each do
      response = {:headers => {"content-type" => ["application/json"]}, :body => "{}"}
      @client = Ripple.client
      @backend = mock("Backend", :store_object => true)
      @client.stub!(:backend).and_return(@backend)
      $pinger = mock("callback verifier")
    end

    it "should call save callbacks on save" do
      Box.before_save { $pinger.ping }
      Box.after_save { $pinger.ping }
      Box.around_save(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.save
    end

    it "propagates callbacks to embedded associated documents" do
      Box.before_save { $pinger.ping }
      BoxSide.before_save { $pinger.ping }
      $pinger.should_receive(:ping).exactly(2).times
      @box = Box.new
      @box.sides << BoxSide.new
      @box.save
    end

    it 'does not persist the object to riak multiple times when propagating callbacks' do
      Box.before_save { }
      BoxSide.before_save { }
      @box = Box.new
      @box.sides << BoxSide.new << BoxSide.new

      @box.robject.should_receive(:store).once
      @box.save
    end

    it 'invokes the before/after callbacks in the correct order on embedded associated documents' do
      callbacks = []
      BoxSide.before_save { callbacks << :before_save }
      BoxSide.after_save  { callbacks << :after_save  }

      @box = Box.new
      @box.sides << BoxSide.new
      @box.robject.stub(:store) do
        callbacks << :save
      end
      @box.save

      callbacks.should == [:before_save, :save, :after_save]
    end

    it 'does not allow around callbacks on embedded associated documents' do
      expect {
        BoxSide.around_save { }
      }.to raise_error(/around_save callbacks are not supported/)
    end

    it 'does not propagate validation callbacks multiple times' do
      Box.before_validation { $pinger.ping }
      BoxSide.before_validation { $pinger.ping }
      $pinger.should_receive(:ping).exactly(2).times
      @box = Box.new
      @box.sides << BoxSide.new
      @box.valid?
    end

    it "should call create callbacks on save when the document is new" do
      Box.before_create { $pinger.ping }
      Box.after_create { $pinger.ping }
      Box.around_create(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.save
    end

    it "should call update callbacks on save when the document is not new" do
      Box.before_update { $pinger.ping }
      Box.after_update { $pinger.ping }
      Box.around_update(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.stub!(:new?).and_return(false)
      @box.save
    end

    it "should call destroy callbacks" do
      Box.before_destroy { $pinger.ping }
      Box.after_destroy { $pinger.ping }
      Box.around_destroy(lambda { $pinger.ping })
      $pinger.should_receive(:ping).exactly(3).times
      @box = Box.new
      @box.destroy
    end

    it "should call save and validate callbacks in the correct order" do
      Box.before_validation { $pinger.ping(:v) }
      Box.before_save { $pinger.ping(:s) }
      $pinger.should_receive(:ping).with(:v).ordered
      $pinger.should_receive(:ping).with(:s).ordered
      @box = Box.new
      @box.save
    end

    describe "validation callbacks" do
      it "should call validation callbacks" do
        Box.before_validation { $pinger.ping }
        Box.after_validation  { $pinger.ping }
        $pinger.should_receive(:ping).twice
        @box = Box.new
        @box.valid?
      end

      it "should call validation callbacks only if the document is new" do
        Box.before_validation(:on => :create) { $pinger.ping }
        Box.after_validation(:on => :create) { $pinger.ping }
        $pinger.should_receive(:ping).twice
        @box = Box.new
        @box.valid?
      end

      it "should not call validation callbacks only if the document is new" do
        Box.before_validation(:on => :update) { $pinger.ping }
        Box.after_validation(:on => :update) { $pinger.ping }
        $pinger.should_not_receive(:ping)
        @box = Box.new
        @box.valid?
      end

      it "should call validation callbacks only if the document is not new" do
        Box.before_validation(:on => :update) { $pinger.ping }
        Box.after_validation(:on => :update) { $pinger.ping }
        $pinger.should_receive(:ping).twice
        @box = Box.new
        @box.stub(:new?).and_return(false)
        @box.valid?
      end

      it "should not call validation callbacks only if the document is not new" do
        Box.before_validation(:on => :create) { $pinger.ping }
        Box.after_validation(:on => :create) { $pinger.ping }
        $pinger.should_not_receive(:ping)
        @box = Box.new
        @box.stub!(:new?).and_return(false)
        @box.valid?
      end
    end

    after :each do
      [:save, :create, :update, :destroy, :validation].each do |type|
        Box.reset_callbacks(type)
        BoxSide.reset_callbacks(type)
      end
    end
  end
end
