require 'spec_helper'
require 'rails/generators/ripple/js/js_generator'

describe Ripple::Generators::JsGenerator do
  before { run_generator }

  it "should create an app/mapreduce directory" do
    file('app/mapreduce').should exist
  end

  it "should copy all standard JS files into the mapreduce directory" do
    Dir[file('app/mapreduce/*')].sort.map{|f| File.basename(f) }.should == %w{contrib.js iso8601.js ripple.js}
  end
end
