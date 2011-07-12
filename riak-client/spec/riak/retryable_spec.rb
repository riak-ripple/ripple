require File.expand_path("../spec_helper", File.dirname(__FILE__))
require 'riak/client/retryable'

class RetryableObject
  include Riak::Client::Retryable
  attr_writer :retryable

  def retryable?(exception, options)
    @retryable.respond_to?(:call) ? @retryable.call(exception,options) : @retryable
  end
end

describe Riak::Client::Retryable  do
  subject { RetryableObject.new }
  let(:not_boom) { proc {|e,o| e.message != "boom" } }
  let(:is_boom) { proc {|e,o| e.message == "boom" } }

  it "should retry exceptions that are retryable" do
    count = 0
    subject.retryable = is_boom
    subject.with_retries do
      count += 1
      raise "boom" if count < 2
      true
    end.should be_true
  end

  it "should not retry exceptions that are not retryable" do
    subject.retryable = not_boom
    expect {
      subject.with_retries do
        raise "boom"
      end
    }.to raise_error
  end

  it "should refresh the connection when retrying" do
    subject.should_receive(:refresh_connection).at_least(:once)
    subject.retryable = true
    expect {
      subject.with_retries do
        raise "boom"
      end
    }.to raise_error
  end

  it "should retry a default of 3 times" do
    count = 0
    subject.retryable = true
    expect {
      subject.with_retries do
        count += 1
        raise "boom"
      end
    }.to raise_error
    count.should == 4
  end

  it "should retry the specified number of times" do
    count = 0
    subject.retryable = true
    expect {
      subject.with_retries(:retries => 1) do
        count += 1
        raise "boom"
      end
    }.to raise_error
    count.should == 2
  end
end
