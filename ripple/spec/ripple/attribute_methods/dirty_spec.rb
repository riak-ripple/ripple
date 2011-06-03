require File.expand_path("../../../spec_helper", __FILE__)

describe Ripple::AttributeMethods::Dirty do
  describe "#changed?" do
    let(:company)    { Company.new }

    it "should capture previous changes when saving" do
      company.robject.stub!(:store).and_return(true)
      company.name = 'Fizz Buzz, Inc.'
      company.save
      company.previous_changes.should include('name')
    end
  end
end
