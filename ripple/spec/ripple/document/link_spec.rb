require File.expand_path("../../../spec_helper", __FILE__)

module Ripple
  module Document
    describe self do
      describe "#to_link" do
        let(:tag)      { 'invoices' }
        let(:document) { Invoice.new }
        let(:to_link)  { document.to_link(tag) }

        it "returns a #{described_class}::Link" do
          to_link.should be_a(Link)
        end

        it "sets the document to this document" do
          to_link.send(:document).should equal(document)
        end

        it "sets the tag to the given tag" do
          to_link.tag.should == tag
        end
      end
    end

    describe Link do
      let(:key)      { 'the-invoice-key' }
      let(:tag)      { 'invoices' }
      let(:document) { Invoice.new { |i| i.key = key } }
      let(:link)     { described_class.new(document, tag) }

      it 'does not fetch the key immediately' do
        document.should_not_receive(:key)
        link
      end

      describe '#key' do
        it "returns the document's key" do
          link.key.should == key
        end
      end

      describe '#bucket' do
        it "returns the bucket name from the document class" do
          link.bucket.should == Invoice.bucket_name
        end
      end

      describe '#tag' do
        it 'returns the tag passed to the constructor' do
          link.tag.should == tag
        end
      end

      describe "#hash" do
        it 'does not use the key' do
          document.should_not_receive(:key)
          link.hash
        end

        it "uses the document's #hash" do
          document.should_receive(:hash).and_return(1234)
          link.hash.should == 1234
        end
      end
    end
  end
end
