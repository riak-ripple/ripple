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
