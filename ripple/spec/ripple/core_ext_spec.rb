# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require File.expand_path("../../spec_helper", __FILE__)

describe Time do
  it "serializes to JSON in UTC, ISO 8601 format" do
    Time.utc(2010,3,16,12).as_json.should == "2010-03-16T12:00:00Z"
  end
end

describe Date do
  it "serializes to JSON ISO 8601 format" do
    Date.civil(2010,3,16).as_json.should == "2010-03-16"
  end
end

describe DateTime do
  before :each do
    Time.zone = :utc
  end

  it "serializes to JSON in UTC, ISO 8601 format" do
    DateTime.civil(2010,3,16,12).as_json.should == "2010-03-16T12:00:00+00:00"
  end
end

describe ActiveSupport::TimeWithZone do
  it "serializes to JSON in UTC, ISO 8601 format" do
    time = Time.utc(2010,3,16,12)
    zone = ActiveSupport::TimeZone['Alaska']
    ActiveSupport::TimeWithZone.new(time, zone).as_json.should == "2010-03-16T12:00:00Z"
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
