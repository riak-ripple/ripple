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

  it "should delay until the next millisecond when the sequence overflows" do
    old = subject.instance_variable_get(:@timestamp) + 0
    subject.instance_variable_set(:@sequence, described_class::SEQUENCE_MASK)
    count = 0
    # Simulate the time_gen method returning the same thing multiple times
    subject.stub(:time_gen) do
      count += 1
      if count < 10
        old
      else
        old + 1
      end
    end
    ((subject.next >> described_class::TIMESTAMP_SHIFT) & described_class::TIMESTAMP_MASK).should == old + 1
  end

  it "should raise an exception when the system clock moves backwards" do
    old = subject.instance_variable_get(:@timestamp)
    subject.should_receive(:time_gen).and_return(old - 10)
    expect {
      subject.next
    }.to raise_error(Riak::BackwardsClockError)
  end

  # The client/worker ID should be used for disambiguation, not for
  # primary ordering.  This breaks from the Snowflake model where the
  # worker ID is in more significant bits.
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
