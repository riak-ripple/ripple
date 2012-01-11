require 'spec_helper'
require 'rails/generators/ripple_generator'

describe RippleGenerator do
  it "should invoke the sub-generators" do
    %w{configuration js test}.each do |gen|
      generator.should_receive(:invoke).with("ripple:#{gen}")
    end
    run_generator
  end
end
