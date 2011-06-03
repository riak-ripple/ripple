require File.expand_path("../../../spec_helper", __FILE__)

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
      class << company
        after_save {|c| c['pc'] = previous_changes }
      end
      company.save
      company['pc'].should include('name')
    end
  end
end
