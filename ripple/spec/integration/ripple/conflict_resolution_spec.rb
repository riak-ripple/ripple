require 'spec_helper'

describe "Ripple conflict resolution" do
  class ConflictedPerson
    include Ripple::Document

    property :name,   String
    property :age,    Integer, :numericality => { :greater_than => 0, :allow_nil => true }
    property :gender, String
    property :favorite_colors, Set, :default => lambda { Set.new }
    property :created_at, DateTime
    property :updated_at, DateTime
    key_on   :name

    bucket.allow_mult = true
  end

  before(:each) do
    ConflictedPerson.on_conflict { } # reset to no-op
  end

  context 'when there is no conflict' do
    it 'does not invoke the on_conflict hook' do
      ConflictedPerson.on_conflict { raise "This conflict hook should not be invoked" }

      # no errors should be raised by the hook above
      ConflictedPerson.find('Noone')
      ConflictedPerson.create!(name: 'John')
      ConflictedPerson.find('John').should_not be_nil
    end
  end

  context 'for a document that has conflicted attributes' do
    let(:created_at) { DateTime.new(2011, 5, 12, 8, 30, 0) }
    let(:updated_at) { DateTime.new(2011, 5, 12, 8, 30, 0) }

    let(:most_recent_updated_at) { DateTime.new(2011, 6, 4, 12, 30) }
    let(:earliest_created_at)    { DateTime.new(2010, 5, 3, 12, 30) }

    let(:original_person) do
      ConflictedPerson.create!(
        :name            => 'John',
        :age             => 25,
        :gender          => 'male',
        :favorite_colors => ['green'],
        :created_at      => created_at,
        :updated_at      => updated_at
      )
    end

    before(:each) do
      create_conflict original_person,
        lambda { |p| p.age = 20; p.created_at = earliest_created_at },
        lambda { |p| p.age = 30; p.updated_at = most_recent_updated_at },
        lambda { |p| p.favorite_colors << 'red' }
    end

    it 'invokes the on_conflict block with the siblings and the list of conflicted attributes' do
      siblings = conflicts = nil
      ConflictedPerson.on_conflict { |s, c| siblings = s; conflicts = c }
      ConflictedPerson.find('John')

      siblings.should have(3).sibling_records
      siblings.map(&:class).uniq.should == [ConflictedPerson]
      siblings.map(&:age).should =~ [20, 25, 30]

      conflicts.should =~ [:age, :favorite_colors]
    end

    it 'automatically resolves any attributes that are in agreement among all siblings' do
      record = nil
      ConflictedPerson.on_conflict { record = self }
      ConflictedPerson.find('John')
      record.name.should == 'John'
      record.gender.should == 'male'
    end

    it 'automatically resolves updated_at to the most recent timestamp' do
      record = nil
      ConflictedPerson.on_conflict { record = self }
      ConflictedPerson.find('John')
      record.updated_at.should == most_recent_updated_at
    end

    it 'automatically resolves created_at to the earliest timestamp' do
      record = nil
      ConflictedPerson.on_conflict { record = self }
      ConflictedPerson.find('John')
      record.created_at.should == earliest_created_at
    end

    it 'automatically sets conflicted attributes to their default values' do
      record = nil
      ConflictedPerson.on_conflict { record = self }
      ConflictedPerson.find('John')
      record.age.should be_nil
      record.favorite_colors.should == Set.new
    end

    it 'returns the resolved record with the changes made by the on_conflict hook' do
      ConflictedPerson.on_conflict do |siblings, _|
        self.age = siblings.map(&:age).inject(&:+)
      end

      person = ConflictedPerson.find('John')
      person.age.should == (20 + 25 + 30)
    end

    it 'saves the resolved record so that it is no longer in conflict' do
      ConflictedPerson.on_conflict do |siblings, _|
        self.age = siblings.map(&:age).inject(&:+)
      end

      ConflictedPerson.find('John')
      ConflictedPerson.on_conflict { raise "The record should no longer be in confict" }
      person = ConflictedPerson.find('John')
      person.age.should == (20 + 25 + 30)
    end

    it 'raises a DocumentInvalid error if the on_conflict block sets the record to an invalid state' do
      ConflictedPerson.on_conflict { self.age = -10 }
      expect {
        ConflictedPerson.find('John')
      }.to raise_error(Ripple::DocumentInvalid)
    end

    context 'when .on_conflict is given a list of attributes' do
      it 'raises an error if attributes not mentioned in the list are in conflict' do
        ConflictedPerson.on_conflict(:age) { }
        expect {
          ConflictedPerson.find('John')
        }.to raise_error(NotImplementedError) # since favorite_colors is also in conflict
      end

      it 'does not raise an error if all conflicted attributes are in the list' do
        ConflictedPerson.on_conflict(:age, :favorite_colors) { }
        ConflictedPerson.find('John')
      end
    end
  end
end
