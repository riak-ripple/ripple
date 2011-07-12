require 'spec_helper'

describe Riak::Util::Multipart do
  it "should extract the boundary string from a header value" do
    Riak::Util::Multipart.extract_boundary("multipart/mixed; boundary=123446677890").should == "123446677890"
  end

  it "should parse an empty multipart body into empty arrays" do
    data = File.read(File.expand_path("#{File.dirname(__FILE__)}/../fixtures/multipart-blank.txt"))
    Riak::Util::Multipart.parse(data, "73NmmA8dJxSB5nL2dVerpFIi8ze").should == [[]]
  end

  it "should parse multipart body into nested arrays with response-like results" do
    data = File.read(File.expand_path("#{File.dirname(__FILE__)}/../fixtures/multipart-with-body.txt"))
    results = Riak::Util::Multipart.parse(data, "5EiMOjuGavQ2IbXAqsJPLLfJNlA")
    results.should be_kind_of(Array)
    results.first.should be_kind_of(Array)
    obj = results.first.first
    obj.should be_kind_of(Hash)
    obj.should have_key(:headers)
    obj.should have_key(:body)
  end
end
