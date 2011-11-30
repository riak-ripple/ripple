require 'spec_helper'

describe "Ripple conflict resolution", :integration => true do
  class ConflictedPerson
    include Ripple::Document

    property :name,   String
    property :age,    Integer, :numericality => { :greater_than => 0, :allow_nil => true }
    property :gender, String
    property :favorite_colors, Set, :default => lambda { Set.new }
    property :created_at, DateTime
    property :updated_at, DateTime
    property :coworker_keys, Array
    property :mother_key, String
    key_on   :name

    # embedded
    one :address, :class_name => 'ConflictedAddress'
    many :jobs, :class_name => 'ConflictedJob'

    # linked
    one :spouse, :class_name => 'ConflictedPerson'
    many :friends, :class_name => 'ConflictedPerson'

    #stored_key
    one :mother, :using => :stored_key, :class_name => 'ConflictedPerson'
    many :coworkers, :using => :stored_key, :class_name => 'ConflictedPerson'
  end

  class ConflictedAddress
    include Ripple::EmbeddedDocument
    property :city, String
  end

  class ConflictedJob
    include Ripple::EmbeddedDocument
    property :title, String
  end

  before :all do
    ConflictedPerson.bucket.allow_mult = true
  end

  before(:each) do
    ConflictedPerson.on_conflict { } # reset to no-op
  end

  context 'when there is no conflict' do
    it 'does not invoke the on_conflict hook' do
      ConflictedPerson.on_conflict { raise "This conflict hook should not be invoked" }

      # no errors should be raised by the hook above
      ConflictedPerson.find('Noone')
      ConflictedPerson.create!(:name => 'John')
      ConflictedPerson.find('John').should_not be_nil
    end
  end

  let(:created_at) { DateTime.new(2011, 5, 12, 8, 30, 0) }
  let(:updated_at) { DateTime.new(2011, 5, 12, 8, 30, 0) }

  let(:original_person) do
    ConflictedPerson.create!(
                             :name            => 'John',
                             :age             => 25,
                             :gender          => 'male',
                             :favorite_colors => ['green'],
                             :address         => ConflictedAddress.new(:city => 'Seattle'),
                             :jobs            => [ConflictedJob.new(:title => 'Engineer')],
                             :spouse          => ConflictedPerson.create!(:name => 'Jill', :gender => 'female'),
                             :friends         => [ConflictedPerson.create!(:name => 'Quinn', :gender => 'male')],
                             :coworkers       => [ConflictedPerson.create!(:name => 'Horace', :gender => 'male')],
                             :mother          => ConflictedPerson.create!(:name => 'Serena', :gender => 'female'),
                             :created_at      => created_at,
                             :updated_at      => updated_at
                             )
  end

  context 'for a document that has a deleted sibling' do
    before(:each) do
      create_conflict original_person,
        lambda { |p| p.destroy! },
        lambda { |p| p.age = 20 },
        lambda { |p| p.age = 30 }
    end

    it 'indicates that one of the siblings was deleted' do
      siblings = nil
      ConflictedPerson.on_conflict { |s, c| siblings = s }
      ConflictedPerson.find('John')

      siblings.should have(3).sibling_records
      deleted, undeleted = siblings.partition(&:deleted?)
      deleted.should have(1).record
      undeleted.should have(2).records
      deleted = deleted.first

      # the deleted record should be totally blank except for the name (since it is the key)
      deleted.attributes.reject { |k, v| v.blank? }.should == {"name" => "John"}
    end

    it 'does not consider the deleted sibling when trying basic resolution of attributes that siblings are in agreement about' do
      record = conflicts = nil
      ConflictedPerson.on_conflict { |s, c| conflicts = c; record = self }
      ConflictedPerson.find('John')

      conflicts.should == [:age]
      record.gender.should == 'male'
      record.favorite_colors.should == ['green'].to_set
    end
  end

  context 'for a document that has conflicted attributes' do
    let(:most_recent_updated_at) { DateTime.new(2011, 6, 4, 12, 30) }
    let(:earliest_created_at)    { DateTime.new(2010, 5, 3, 12, 30) }

    before(:each) do
      create_conflict original_person,
      lambda { |p| p.age = 20; p.created_at = earliest_created_at },
      lambda { |p| p.age = 30; p.updated_at = most_recent_updated_at },
      lambda { |p| p.favorite_colors << 'red' }
    end

    it 'raises a NotImplementedError when there is no on_conflict handler' do
      ConflictedPerson.instance_variable_get(:@on_conflict_block).should_not be_nil
      ConflictedPerson.instance_variable_set(:@on_conflict_block, nil)

      expect {
        ConflictedPerson.find('John')
      }.to raise_error(NotImplementedError)
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

    it "reloads a document with conflicts" do
      record = original_person.reload
      record.updated_at.should == most_recent_updated_at
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

  context 'when there are conflicts on a one embedded association' do
    before(:each) do
      create_conflict original_person,
      lambda { |p| p.address.city = 'San Francisco' },
      lambda { |p| p.address.city = 'Portland' }
    end

    it 'sets the association to nil and includes its name in the list of conflicts passed to the on_conflict block' do
      siblings = conflicts = record = nil
      ConflictedPerson.on_conflict { |*a| siblings, conflicts = *a; record = self }
      ConflictedPerson.find('John')
      record.address.should be_nil
      conflicts.should == [:address]
      siblings.map { |s| s.address.city }.should =~ ['Portland', 'San Francisco']
    end
  end

  context 'when there are conflicts on a many embedded association' do
    before(:each) do
      create_conflict original_person,
      lambda { |p| p.jobs << ConflictedJob.new(:title => 'CEO') },
      lambda { |p| p.jobs << ConflictedJob.new(:title => 'CTO') }
    end

    it 'sets the association to an empty array and includes its name in the list of conflicts passed to the on_conflict block' do
      siblings = conflicts = record = nil
      ConflictedPerson.on_conflict { |*a| siblings, conflicts = *a; record = self }
      ConflictedPerson.find('John')
      record.jobs.should == []
      conflicts.should == [:jobs]
      siblings.map { |s| s.jobs.map(&:title) }.should =~ [["Engineer", "CEO"], ["Engineer", "CTO"]]
    end
  end

  context 'when there are conflicts on a one linked association' do
    before(:each) do
      create_conflict original_person,
      lambda { |p| p.spouse = ConflictedPerson.create!(:name => 'Renee', :gender => 'female') },
      lambda { |p| p.spouse = ConflictedPerson.create!(:name => 'Sharon', :gender => 'female') }
    end

    it 'sets the association to nil and includes its name in the list of conflicts passed to the on_conflict block' do
      record_spouse = conflicts = sibling_spouse_names = nil

      ConflictedPerson.on_conflict do |siblings, c|
        record_spouse = spouse
        conflicts = c
        sibling_spouse_names = siblings.map { |s| s.spouse.name }
      end

      ConflictedPerson.find('John')
      record_spouse.should be_nil
      conflicts.should == [:spouse]
      sibling_spouse_names.should =~ %w[ Sharon Renee ]
    end
  end

  context 'when there are conflicts on a many linked association' do
    before(:each) do
      create_conflict original_person,
      lambda { |p| p.friends << ConflictedPerson.new(:name => 'Luna', :gender => 'female') },
      lambda { |p| p.friends << ConflictedPerson.new(:name => 'Molly', :gender => 'female') }
    end

    it 'sets the association to a blank array and includes its name in the list of conflicts passed to the on_conflict block' do
      record_friends = conflicts = sibling_friend_names = nil

      ConflictedPerson.on_conflict do |siblings, c|
        record_friends = friends
        conflicts = c
        sibling_friend_names = siblings.map { |s| s.friends.map(&:name) }
      end

      ConflictedPerson.find('John')
      record_friends.should == []
      conflicts.should == [:friends]
      sibling_friend_names.map(&:sort).should =~ [['Luna', 'Quinn'], ['Molly', 'Quinn']]
    end
  end

  context 'when there are conflicts on a many stored_key association' do
    before(:each) do
      create_conflict original_person,
      lambda { |p| p.coworkers << ConflictedPerson.create!(:name => 'Colleen', :gender => 'female') },
      lambda { |p| p.coworkers = [ ConflictedPerson.create!(:name => 'Russ', :gender => 'male'),
                                   ConflictedPerson.create!(:name => 'Denise', :gender => 'female') ] }
    end

    it 'sets the association to a blank array and includes the owner_keys in the list of conflicts passed to the on_conflict block' do
      record_coworkers = record_coworker_keys = conflicts = sibling_coworker_keys = nil

      ConflictedPerson.on_conflict do |siblings, c|
        record_coworkers = coworkers
        record_coworker_keys = coworker_keys
        conflicts = c
        sibling_coworker_keys = siblings.map { |s| s.coworker_keys }
      end

      ConflictedPerson.find('John')
      record_coworker_keys.should == []
      record_coworkers.should == []
      conflicts.should == [:coworker_keys]
      sibling_coworker_keys.map(&:sort).should =~ [['Colleen', 'Horace'], ['Denise', 'Russ']]
    end
  end

  context 'when there are conflicts on a one stored_key association' do
    before(:each) do
      create_conflict original_person,
      lambda { |p| p.mother = ConflictedPerson.new(:name => 'Nancy', :gender => 'female') },
      lambda { |p| p.mother = ConflictedPerson.new(:name => 'Sherry', :gender => 'male') }
    end

    it 'sets the association to nil and includes its name in the list of conflicts passed to the on_conflict block' do
      record_mother = conflicts = sibling_mother_keys = nil

      ConflictedPerson.on_conflict do |siblings, c|
        record_mother = mother
        conflicts = c
        sibling_mother_keys = siblings.map { |s| s.mother_key }
      end

      ConflictedPerson.find('John')
      record_mother.should be_nil
      conflicts.should == [:mother_key]
      sibling_mother_keys.sort.should == %w(Nancy Sherry)
    end
  end
end
