require 'spec_helper'

describe Ripple::AttributeMethods::Dirty do
  let(:company)    { Company.new }
  let(:ceo)        { CEO.new(:name => 'John Doe') }
  let(:department) { Department.new(:name => 'Marketing') }
  let(:manager)    { Manager.new(:name => 'Billy Willy') }
  let(:invoice)    { Invoice.new }

  describe "previous_changes" do
    before do
      company.robject.stub!(:store).and_return(true)
      company.name = 'Fizz Buzz, Inc.'
    end

    it "should capture previous changes when saving" do
      company.save
      company.previous_changes.should include('name')
    end

    it "should make previous changes available to after callbacks" do
      my_class = Class.new(Company) do
        after_save {|c| c['pc'] = previous_changes }
      end
      comp = my_class.new
      comp.robject.stub!(:store).and_return(true)
      comp.name = 'Fizz Buzz, Inc.'
      comp.save
      comp['pc'].should include('name')
    end
  end

  describe "#changed?" do

    it "returns true if the document's attributes have changed (regardless of whether or not it has any embedded associated documents)" do
      company.name = 'Fizz Buzz, Inc'
      company.should be_changed
    end


    context "when the document's attributes have not changed" do
      it 'returns false if it has no embedded associated documents' do
        company.should_not be_changed
      end

      context 'when the document has embedded associated documents' do
        before(:each) do
          company.ceo = ceo
          company.invoices << invoice
          company.departments << department
          department.managers << manager
        end

        it 'returns false if all the embedded documents are not changed' do
          company.should_not be_changed
        end

        it 'does not consider changes to linked associated documents' do
          invoice.should_not_receive(:changed?)
          company.changed?
        end

        it 'returns true if a one embedded association document is changed' do
          ceo.should_receive(:changed?).and_return(true)
          company.should be_changed
        end

        it 'returns true if a many embedded association document is changed' do
          department.should_receive(:changed?).and_return(true)
          company.should be_changed
        end

        it 'recurses through the whole embedded document structure to find changed grandchild documents' do
          manager.should_receive(:changed?).and_return(true)
          company.should be_changed
        end
      end
    end
  end
end
