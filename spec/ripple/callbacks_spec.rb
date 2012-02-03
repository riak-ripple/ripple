require 'spec_helper'

describe Ripple::Callbacks do
  let(:doc) do
    _e = embedded
    Class.new do
      include Ripple::Document
      self.bucket_name = "docs"
      many :embeddeds, :class => _e
    end
  end

  let(:embedded) do
    Class.new do
      include Ripple::EmbeddedDocument
    end
  end

  subject { doc.new }

  it "should add create, update, save, and destroy callback declarations" do
    [:save, :create, :update, :destroy].each do |event|
      doc.private_instance_methods.map(&:to_s).should include("_run_#{event}_callbacks")
      [:before, :after, :around].each do |time|
        doc.should respond_to("#{time}_#{event}")
      end
    end
  end

  it "should validate callback declarations" do
    doc.private_instance_methods.map(&:to_s).should include("_run_validation_callbacks")
    doc.should respond_to("before_validation")
    doc.should respond_to("after_validation")
  end

  describe "invoking callbacks" do
    before :each do
      @client = Ripple.client
      @client.stub(:store_object => true)
    end

    it "should call save callbacks on save" do
      callbacks = []
      doc.before_save { callbacks << :before }
      doc.after_save { callbacks << :after }
      doc.around_save(lambda { callbacks << :around })
      subject.save
      callbacks.should == [ :before, :around, :after ]
    end

    it "propagates callbacks to embedded associated documents" do
      callbacks = []
      doc.before_save { callbacks << :box }
      embedded.before_save { callbacks << :side }
      subject.embeddeds << embedded.new
      subject.save
      callbacks.should == [:side, :box]
    end

    it 'does not persist the object to riak multiple times when propagating callbacks' do
      doc.before_save { }
      embedded.before_save { }
      subject.embeddeds << embedded.new << embedded.new

      subject.robject.should_receive(:store).once
      subject.save
    end

    it 'invokes the before/after callbacks in the correct order on embedded associated documents' do
      callbacks = []
      embedded.before_save { callbacks << :before_save }
      embedded.after_save  { callbacks << :after_save  }

      subject.embeddeds << embedded.new
      subject.robject.stub(:store) do
        callbacks << :save
      end
      subject.save

      callbacks.should == [:before_save, :save, :after_save]
    end

    it 'does not allow around callbacks on embedded associated documents' do
      expect {
        embedded.around_save { }
      }.to raise_error(/around_save callbacks are not supported/)
    end

    it 'does not propagate validation callbacks multiple times' do
      callbacks = []
      doc.before_validation { callbacks << :box }
      embedded.before_validation { callbacks << :side }

      subject.embeddeds << embedded.new
      subject.valid?
      callbacks.should == [:box, :side]
    end

    it "should call create callbacks on save when the document is new" do
      callbacks = []
      doc.before_create { callbacks << :before }
      doc.after_create { callbacks << :after }
      doc.around_create(lambda { callbacks << :around })

      subject.save
      callbacks.should == [:before, :around, :after ]
    end

    it "should call update callbacks on save when the document is not new" do
      callbacks = []
      doc.before_update { callbacks << :before }
      doc.after_update { callbacks << :after }
      doc.around_update(lambda { callbacks << :around })

      subject.stub!(:new?).and_return(false)
      subject.save
      callbacks.should == [:before, :around, :after ]
    end

    describe "destroy callbacks" do
      let(:callbacks) { [] }

      before(:each) do
        _callbacks = callbacks
        doc.before_destroy { _callbacks << :before }
        doc.after_destroy { _callbacks << :after }
        doc.around_destroy(lambda { _callbacks << :around })
      end

      after { callbacks.should == [ :before, :around, :after ] }

      it "invokes them when #destroy is called" do
        subject.destroy
      end

      it "invokes them when #destroy! is called" do
        subject.destroy!
      end
    end

    it "should call save and validate callbacks in the correct order" do
      callbacks = []
      doc.before_validation { callbacks << :validation }
      doc.before_save { callbacks << :save }

      subject.save
      callbacks.should == [:validation, :save]
    end

    describe "validation callbacks" do
      it "should call validation callbacks" do
        callbacks = []
        doc.before_validation { callbacks << :before }
        doc.after_validation  { callbacks << :after }
        subject.valid?
        callbacks.should == [:before, :after]
      end

      it "should call validation callbacks only if the document is new" do
        callbacks = []
        doc.before_validation(:on => :create) { callbacks << :before }
        doc.after_validation(:on => :create) { callbacks << :after }
        subject.valid?
        callbacks.should == [:before, :after]
      end

      it "should not call validation callbacks only if the document is new" do
        callbacks = []
        doc.before_validation(:on => :update) { callbacks << :before }
        doc.after_validation(:on => :update) { callbacks << :after }
        subject.valid?
        callbacks.should be_empty
      end

      it "should call validation callbacks only if the document is not new" do
        callbacks = []
        doc.before_validation(:on => :update) { callbacks << :before }
        doc.after_validation(:on => :update) { callbacks << :after }

        subject.stub(:new?).and_return(false)
        subject.valid?
        callbacks.should == [:before, :after]
      end

      it "should not call validation callbacks only if the document is not new" do
        callbacks = []
        doc.before_validation(:on => :create) { callbacks << :validation }
        doc.after_validation(:on => :create) { callbacks << :after }
        subject.stub!(:new?).and_return(false)
        subject.valid?
        callbacks.should be_empty
      end
    end
  end
end
