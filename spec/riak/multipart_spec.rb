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
require File.expand_path("../spec_helper", File.dirname(__FILE__))

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
