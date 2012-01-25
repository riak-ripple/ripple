require 'spec_helper'

describe Ripple::Conversion do
  # require 'support/models/box'
  subject { Box.new { |a| a.key = 'some-key' } }

  before :each do
    subject.stub!(:new?).and_return(false)
  end

  its(:to_key)  { should == ['some-key'] }
  its(:to_param){ should == 'some-key'   }
  its(:to_model){ should == subject      }
end
