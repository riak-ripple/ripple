require File.expand_path("../../../spec_helper", __FILE__)

describe Ripple::AttributeMethods::Dirty do
  describe "#has_changes?" do
    let(:company)    { Company.new(:name => 'FizzBuzz, Inc') }
    let(:ceo)        { CEO.new(:name => 'John Doe') }
    let(:department) { Department.new(:name => 'Marketing') }
    let(:manager)    { Manager.new(:name => 'Billy Willy') }
    let(:invoice)    { Invoice.new }

    it "returns true if the document's attributes have changed (regardless of whether or not it has any embedded associated documents)" do
      company.should_receive(:changed?).and_return(true)
      company.should have_changes
    end

    context "when the document's attributes have not changed" do
      before(:each) { company.stub(:changed? => false) }

      it 'returns false if it has no embedded associated documents' do
        company.should_not have_changes
      end

      context 'when the document has embedded associated documents' do
        before(:each) do
          company.ceo = ceo
          company.invoices << invoice
          company.departments << department
          department.managers << manager

          ceo.stub(:changed? => false)
          department.stub(:changed? => false)
          manager.stub(:changed? => false)
          invoice.stub(:changed? => false)
        end

        it 'returns false if all the embedded documents have no changes' do
          company.should_not have_changes
        end

        it 'does not consider changes to linked associated documents' do
          invoice.should_not_receive(:changed?)
          company.has_changes?
        end

        it 'returns true if a one embedded association document has changes' do
          ceo.should_receive(:changed?).and_return(true)
          company.should have_changes
        end

        it 'returns true if a many embedded association document has changes' do
          department.should_receive(:changed?).and_return(true)
          company.should have_changes
        end

        it 'recurses through the whole embedded document structure to find changes in grandchild documents' do
          manager.should_receive(:changed?).and_return(true)
          company.should have_changes
        end
      end
    end
  end
end
