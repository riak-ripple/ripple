require File.expand_path("../../spec_helper", __FILE__)

describe Time do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }

  it "serializes to JSON in UTC, ISO 8601 format by default" do
    Time.utc(2010,3,16,12).as_json.should == "2010-03-16T12:00:00Z"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    Time.utc(2010,3,16,12).as_json.should == "Tue, 16 Mar 2010 12:00:00 -0000"
  end
end

describe Date do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }

  it "serializes to JSON ISO 8601 format by default" do
    Date.civil(2010,3,16).as_json.should == "2010-03-16"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    Date.civil(2010,3,16).as_json.should == "16 Mar 2010"
  end
end

describe DateTime do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }

  before :each do
    Time.zone = :utc
  end

  it "serializes to JSON in UTC, ISO 8601 format by default" do
    DateTime.civil(2010,3,16,12).as_json.should == "2010-03-16T12:00:00+00:00"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    DateTime.civil(2010,3,16,12).as_json.should == "Tue, 16 Mar 2010 12:00:00 +0000"
  end
end

describe ActiveSupport::TimeWithZone do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }

  it "serializes to JSON in UTC, ISO 8601 format by default" do
    time = Time.utc(2010,3,16,12)
    zone = ActiveSupport::TimeZone['Alaska']
    ActiveSupport::TimeWithZone.new(time, zone).as_json.should == "2010-03-16T12:00:00Z"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    time = Time.utc(2010,3,16,12)
    zone = ActiveSupport::TimeZone['Alaska']
    ActiveSupport::TimeWithZone.new(time, zone).as_json.should == "Tue, 16 Mar 2010 12:00:00 -0000"
  end
end

describe String do
  it "can parse RFC 822 and ISO 8601 times" do
    'Tue, 16 Mar 2010 12:00:00 -0000'.to_time.should == Time.utc(2010,3,16,12)
    '2010-03-16T12:00:00Z'.to_time.should == Time.utc(2010,3,16,12)
  end

  it "can parse RFC 822 and ISO 8601 dates" do
    '16 Mar 2010'.to_date.should == Date.civil(2010,3,16)
    '2010-3-16'.to_date.should == Date.civil(2010,3,16)
  end

  it "can parse RFC 822 and ISO 8601 datetimes" do
    'Tue, 16 Mar 2010 12:00:00 +0000'.to_datetime.should == DateTime.civil(2010,3,16,12)
    '2010-03-16T12:00:00+00:00'.to_datetime.should == DateTime.civil(2010,3,16,12)
  end
end

describe "Boolean" do
  it "should be available to properties on documents" do
    lambda {
      class BooleanTest
        include Ripple::Document
        property :foo, Boolean
      end
    }.should_not raise_error(NameError)
  end
end
