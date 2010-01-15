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
require File.join(File.dirname(__FILE__), "spec_helper")

describe Riak::Binary do
  it "should match image types" do
    %w{gif jpeg jfif bmp}.each do |t|
      Riak::Binary.should be_matches("content-type" => ["image/#{t}"])
    end
  end

  it "should match audio types" do
    %w{mpeg wav aiff}.each do |t|
      Riak::Binary.should be_matches("content-type" => ["audio/#{t}"])
    end
  end

  it "should match video types" do
    %w{mp4 mov avi}.each do |t|
      Riak::Binary.should be_matches("content-type" => ["video/#{t}"])
    end    
  end

  it "should match MIME multipart types" do
    %w{mixed alternative}.each do |t|
      Riak::Binary.should be_matches("content-type" => ["multipart/#{t}"])
    end
  end

  it "should match arbitrary application types" do
    %w{vnd.ms-works zip marc}.each do |t|
      Riak::Binary.should be_matches("content-type" => ["application/#{t}"])
    end
  end
end
