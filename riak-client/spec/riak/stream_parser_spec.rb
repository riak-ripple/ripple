require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::Util::Multipart::StreamParser do
  let(:klass) { Riak::Util::Multipart::StreamParser }
  let(:block) { mock }
  it "should detect the initial boundary" do
    text = "--boundary1\r\nContent-Type: text/plain\r\n\r\nfoo\r\n--boundary1--\r\n"
    parser = klass.new do |result|
      result[:headers]['content-type'].should include("text/plain")
      result[:body].should == "foo"
    end
    parser.accept text
  end

  it "should detect inner multipart bodies" do
    block.should_receive(:ping).once.and_return(true)
    parser = klass.new do |result|
      block.ping
      result.should have(1).item
      result.first[:headers]['content-type'].should include("text/plain")
      result.first[:body].should == "SCP sloooow...."
    end
    File.open("spec/fixtures/multipart-with-body.txt", "r") do |f|
      while chunk = f.read(16)
        parser.accept chunk
      end
    end
  end

  it "should yield successive complete chunks to the block" do
    block.should_receive(:ping).twice.and_return(true)
    parser = klass.new do |result|
      block.ping
      result[:headers]['content-type'].should include("application/json")
      lambda { Riak::JSON.parse(result[:body]) }.should_not raise_error
    end
    File.open("spec/fixtures/multipart-mapreduce.txt", "r") do |f|
      while chunk = f.read(16)
        parser.accept chunk
      end
    end
  end

  it "should yield successive complete bodies to the block, even when multiple bodies are accepted in a single chunk" do
    block.should_receive(:ping).twice.and_return(true)
    parser = klass.new do |result|
      block.ping
      result[:headers]['content-type'].should include("application/json")
      lambda { Riak::JSON.parse(result[:body]) }.should_not raise_error
    end
    parser.accept File.read("spec/fixtures/multipart-mapreduce.txt")
  end
end
