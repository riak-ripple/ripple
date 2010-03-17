require File.expand_path("../../spec_helper", __FILE__)

describe Time do
  it "serializes to JSON in UTC, RFC 822 format" do
    Time.utc(2010,3,16,12).as_json.should == "Tue, 16 Mar 2010 12:00:00 -0000"
  end
end

describe Date do
  it "serializes to JSON RFC 822 format" do
    Date.civil(2010,3,16).as_json.should == "16 Mar 2010"
  end
end

describe DateTime do
  before :each do
    Time.zone = :utc
  end

  it "serializes to JSON in UTC, RFC 822 format" do
    DateTime.civil(2010,3,16,12).as_json.should == "Tue, 16 Mar 2010 12:00:00 +0000"
  end
end
