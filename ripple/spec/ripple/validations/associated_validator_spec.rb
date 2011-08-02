require 'spec_helper'

describe Ripple::Validations::AssociatedValidator do
  context 'for a one association' do
    # require 'support/models/family'

    let(:child)  { Child.new  }
    let(:parent) { Parent.new }
    before(:each) { parent.child = child }

    it "is invalid when the associated record is invalid" do
      child.should_not be_valid
      parent.should_not be_valid
    end

    it "includes the associated record's validation error messages in the error message" do
      parent.valid?
      parent.errors[:child].size.should == 1
      parent.errors[:child].first.should =~ /is invalid \(Name can't be blank and Age can't be blank\)/
    end

    it "is valid when the associated record is valid" do
      child.name = 'Coen'
      child.age = 1
      child.should be_valid
      parent.should be_valid
    end
  end

  context 'for a many association' do
    # require 'support/models/team'

    let(:team) { Team.new }
    let(:ichiro) { Player.new(:name => 'Ichiro', :position => 'Right Field') }
    let(:satchel_paige) { Player.new(:position => 'Pitcher') }
    let(:unknown) { Player.new }

    before(:each) do
      team.players << ichiro
      team.players << satchel_paige
      team.players << unknown
    end

    it 'is invalid when the associated records are invalid' do
      satchel_paige.should_not be_valid
      unknown.should_not be_valid
      team.should_not be_valid
    end

    it "includes the associated records' validation error messages in the error message" do
      team.valid?
      team.errors[:players].size.should == 1

      expected_errors = [
        "for player 2: Name can't be blank",
        "for player 3: Name can't be blank and Position can't be blank"
      ]

      expected_errors = expected_errors.join('; ')
      team.errors[:players].first.should == "are invalid (#{expected_errors})"
    end

    it 'is valid when the associated records are all valid' do
      ichiro.position = 'Right Field'
      ichiro.should be_valid

      satchel_paige.name = 'Satchel Paige'
      satchel_paige.should be_valid

      unknown.name = 'John Doe'
      unknown.position = 'First Base'
      unknown.should be_valid

      team.should be_valid
    end
  end
end
