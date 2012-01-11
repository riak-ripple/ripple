require 'spec_helper'
require 'rails/generators/ripple/observer/observer_generator'

describe Ripple::Generators::ObserverGenerator do
  context "in the top-level scope" do
    before { run_generator %w{person} }
    subject{ file('app/models/person_observer.rb') }

    it { should exist }
    it { should contain("class PersonObserver < ActiveModel::Observer") }
  end

  context "in a nested scope" do
    before { run_generator %w{profiles/social} }
    subject { file('app/models/profiles/social_observer.rb') }

    it { should exist }
    it { should contain("class Profiles::SocialObserver < ActiveModel::Observer") }
  end
end
