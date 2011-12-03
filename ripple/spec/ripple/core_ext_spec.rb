require 'spec_helper'

describe Time do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }
  subject { Time.utc(2010,3,16,12) }
  it "serializes to JSON in UTC, ISO 8601 format by default" do
    subject.as_json.should == "2010-03-16T12:00:00Z"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    subject.as_json.should == "Tue, 16 Mar 2010 12:00:00 -0000"
  end

  context "converting to an index value" do
    it "should convert to an integer epoch milliseconds for 'int' type" do
      subject.to_ripple_index('int').should == 1268740800000
    end

    it "should convert to the date format for 'bin' type" do
      subject.to_ripple_index('bin').should == "2010-03-16T12:00:00Z"
    end
  end
end

describe Date do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }
  subject { Date.civil(2010,3,16) }
  it "serializes to JSON ISO 8601 format by default" do
    subject.as_json.should == "2010-03-16"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    subject.as_json.should == "16 Mar 2010"
  end

  context "converting to an index value" do
    it "should convert to an integer epoch milliseconds for 'int' type" do
      subject.to_ripple_index('int').should == 1268697600000
    end

    it "should convert to the date format for 'bin' type" do
      subject.to_ripple_index('bin').should == "2010-03-16"
    end
  end
end

describe DateTime do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }
  subject { DateTime.civil(2010,3,16,12) }
  before :each do
    Time.zone = "UTC"
  end

  it "serializes to JSON in UTC, ISO 8601 format by default" do
    subject.as_json.should == "2010-03-16T12:00:00+00:00"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    subject.as_json.should == "Tue, 16 Mar 2010 12:00:00 +0000"
  end

  context "converting to an index value" do
    it "should convert to an integer epoch milliseconds for 'int' type" do
      subject.to_ripple_index('int').should == 1268740800000
    end

    it "should convert to the date format for 'bin' type" do
      subject.to_ripple_index('bin').should == "2010-03-16T12:00:00+00:00"
    end
  end
end

describe ActiveSupport::TimeWithZone do
  before { @date_format = Ripple.date_format }
  after  { Ripple.date_format = @date_format }
  let(:time) { Time.utc(2010,3,16,12) }
  let(:zone) { ActiveSupport::TimeZone['Alaska'] }
  subject { ActiveSupport::TimeWithZone.new(time, zone) }

  it "serializes to JSON in UTC, ISO 8601 format by default" do
    subject.as_json.should == "2010-03-16T12:00:00Z"
  end

  it "serializes to JSON in UTC, RFC822 format when specified" do
    Ripple.date_format = :rfc822
    subject.as_json.should == "Tue, 16 Mar 2010 12:00:00 -0000"
  end

  context "converting to an index value" do
    it "should convert to an integer epoch milliseconds for 'int' type" do
      subject.to_ripple_index('int').should == 1268740800000
    end

    it "should convert to the date format for 'bin' type" do
      subject.to_ripple_index('bin').should == "2010-03-16T12:00:00Z"
    end
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

describe Set do
  describe "#as_json" do
    it 'returns an array of the #as_json result of each element' do
      set = Set.new([stub(:as_json => 's1'), stub(:as_json => 's2')])
      set.as_json.should =~ ['s1', 's2']
    end
  end
end

describe Enumerable do
  subject { [1,2,3] }
  let(:int) { subject.to_ripple_index('int') }
  let(:bin) { subject.to_ripple_index('bin') }

  context "converting to an index value" do
    it "should convert to a Set of strings for 'bin' type" do
      bin.should be_kind_of(Set)
      %w{1 2 3}.each do |i|
        bin.should include(i)
      end
    end

    it "should convert to a Set of integers for 'int' type" do
      int.should be_kind_of(Set)
      subject.each do |i|
        int.should include(i)
      end
    end
  end
end
