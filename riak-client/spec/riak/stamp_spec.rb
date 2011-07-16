require 'spec_helper'
require 'riak/stamp'

describe Riak::Stamp do
  subject { described_class.new(Riak::Client.new) }
  it "should generate always increasing integer identifiers" do
    1000.times do
      one = subject.next
      two = subject.next
      [one, two].should be_all {|i| Integer === i }
      two.should > one
    end
  end

  it "should raise an exception when the system clock moves backwards" do
    old = subject.instance_variable_get(:@timestamp)
    subject.should_receive(:timestamp).and_return(old - 10)
    expect {
      subject.next
    }.to raise_error(Riak::BackwardsClockError)
  end
  
  it "should use the client ID as the bottom component of the identifier" do
    (subject.next & described_class::CLIENT_ID_MASK).should == subject.client.client_id & described_class::CLIENT_ID_MASK
  end

  context "using a non-integer client ID" do
    subject { described_class.new(Riak::Client.new(:client_id => "ripple")) }
    let(:hash) { "ripple".hash }

    it "should use the hash of the client ID as the bottom component of the identifier" do
      (subject.next & described_class::CLIENT_ID_MASK).should == subject.client.client_id.hash & described_class::CLIENT_ID_MASK
    end
  end
end
