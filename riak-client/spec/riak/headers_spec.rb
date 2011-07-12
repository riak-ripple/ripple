require 'spec_helper'

describe Riak::Util::Headers do
  it "should include the Net::HTTPHeader module" do
    Riak::Util::Headers.included_modules.should include(Net::HTTPHeader)
  end

  it "should be initially empty" do
    Riak::Util::Headers.new.to_hash.should == {}
  end

  it "should parse a header line into the key and value" do
    Riak::Util::Headers.parse("Content-Type: text/plain\r\n").should == ["Content-Type", "text/plain"]
  end

  it "should parse a header line and add it to the collection" do
    h = Riak::Util::Headers.new
    h.parse("Content-Type: text/plain\r\n")
    h.to_hash.should == {"content-type" => ["text/plain"]}
  end

  it "should split headers larger than 8KB" do
    # This really tests Net::HTTPHeader#each_capitalized, which is
    # used by Net::HTTP to write the headers to the socket. It does
    # not cover the case where a single value is larger than 8KB. If
    # you're doing that, you have something else wrong.
    h = Riak::Util::Headers.new
    10.times do
      h.add_field "Link", "f" * 820
    end
    count = 0
    h.each_capitalized do |k,v|
      count += 1
      "#{k}: #{v}\r\n".length.should < 8192
    end
    count.should > 1
  end
end
