require 'spec_helper'
require 'rails/generators/ripple/configuration/configuration_generator'

describe Ripple::Generators::ConfigurationGenerator do
  before { run_generator }
  it "should generate the ripple.yml file" do
    file('config/ripple.yml').should exist
  end
end
