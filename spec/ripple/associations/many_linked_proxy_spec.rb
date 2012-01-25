require 'spec_helper'

describe Ripple::Associations::ManyLinkedProxy do
  # require 'support/models/tasks'

  before :each do
    @person = Person.new {|p| p.key = "riak-user" }
    @task = Task.new {|t| t.key = "one" }
    @other_task = Task.new {|t| t.key = "two" }
    @third_task = Task.new {|t| t.key = "three" }
    [@person, @task, @other_task].each do |doc|
      doc.stub!(:new?).and_return(false)
    end
  end

  it "should be empty before any associated documents are set" do
    @person.tasks.should be_empty
  end

  it "should accept an array of documents" do
    @person.tasks = [@task]
  end

  it "should set the links on the RObject when assigning" do
    @person.tasks = [@task]
    @person.robject.links.should include(@task.to_link("tasks"))
  end

  it "should be able to replace the entire collection of documents (even appended ones)" do
    @person.tasks << @task
    @person.tasks = [@other_task]
    @person.tasks.should == [@other_task]
  end

  it "should return the assigned documents when assigning" do
    t = (@person.tasks = [@task])
    t.should == [@task]
  end

  it "should link-walk to the associated documents when accessing" do
    @person.robject.links << @task.to_link("tasks")
    @person.robject.should_receive(:walk).with(Riak::WalkSpec.new(:bucket => "tasks", :tag => "tasks")).and_return([])
    @person.tasks.should == []
  end

  it "handles conflict appropriately by selecting the linked-walk robjects that match the links" do
    @person.robject.links << @task.to_link("tasks") << @other_task.to_link("tasks")
    @person.robject.
      should_receive(:walk).
      with(Riak::WalkSpec.new(:bucket => "tasks", :tag => "tasks")).
      and_return([[@task.robject, @other_task.robject, @third_task.robject]])

    @person.tasks.should == [@task, @other_task]
  end

  it "allows the links to be replaced directly" do
    @person.tasks = [@task]
    @person.tasks.__send__(:should_receive, :reset)
    @person.tasks.__send__(:links).should == [@task.robject.to_link("tasks")]
    @person.tasks.replace_links([@other_task, @third_task].map { |t| t.robject.to_link("tasks") })
    @person.tasks.__send__(:links).should =~ [@other_task, @third_task].map { |t| t.robject.to_link("tasks") }
  end

  it "should replace associated documents with a new set" do
    @person.tasks = [@task]
    @person.tasks = [@other_task]
    @person.tasks.should == [@other_task]
  end

  it "asks the keys set for the count to avoid having to unnecessarily load all documents" do
    @person.tasks.keys.stub(:size => 17)
    @person.tasks.count.should == 17
  end

  # it "should be able to build a new associated document" do
  #   pending "Need unsaved document support"
  # end

  it "should return an array from to_ary" do
    @person.tasks << @task
    @person.tasks.to_ary.should == [@task]
  end

  it "should refuse assigning a collection of the wrong type" do
    lambda { @person.tasks = nil }.should raise_error
    lambda { @person.tasks = @task }.should raise_error
    lambda { @person.tasks = [@person] }.should raise_error
  end

  describe "#<< (when the target has not already been loaded)" do
    it "avoids link-walking when adding a record to an unloaded association" do
      @person.robject.should_not_receive(:walk)
      @person.tasks << @task
    end

    it "should be able to count the associated documents" do
      @person.tasks << @task
      @person.tasks.count.should == 1
      @person.tasks << @other_task
      @person.tasks.count.should == 2
    end

    it "maintains the list of keys properly as new documents are appended" do
      @person.tasks << @task
      @person.tasks.should have(1).key
      @person.tasks << @other_task
      @person.tasks.should have(2).keys
    end

    it "should be able to append documents to the associated set" do
      @person.tasks << @task
      @person.tasks << @other_task
      @person.should have(2).tasks
    end

    it "should be able to chain calls to adding documents" do
      @person.tasks << @task << @other_task
      @person.should have(2).tasks
    end

    it "should set the links on the RObject when appending" do
      @person.tasks << @task << @other_task
      [@task, @other_task].each do |t|
        @person.robject.links.should include(t.to_link("tasks"))
      end
    end

    it "does not return duplicates (for when the object has been appended and it's robject is found while walking the links)" do
      @person.tasks.stub(:robjects => [@task.robject])
      @person.tasks.reset
      @person.tasks << @task
      @person.tasks.should == [@task]
    end
  end

  describe "#reset" do
    it "clears appended documents" do
      @person.tasks << @task
      @person.tasks.reset
      @person.tasks.should == []
    end
  end

  describe "#keys" do
    let(:link_keys) { %w[ 1 2 3 ] }
    let(:links) { link_keys.map { |k| Riak::Link.new('tasks', k, 'task') } }

    before(:each) do
      @person.tasks.stub(:links => links)
    end

    it "returns a set of keys" do
      @person.tasks.keys.should be_a(Set)
      @person.tasks.keys.to_a.should =~ link_keys
    end

    it "is memoized between calls" do
      @person.tasks.keys.should equal(@person.tasks.keys)
    end

    it "is cleared when the association is reset" do
      orig_set = @person.tasks.keys
      @person.tasks.reset
      @person.tasks.keys.should_not equal(orig_set)
    end

    it "is cleared when the association is replaced" do
      orig_set = @person.tasks.keys
      @person.tasks.replace([@task])
      @person.tasks.keys.should_not equal(orig_set)
    end
  end

  describe "#include?" do
    it "delegates to the set of keys so as not to unnecessarily load the associated documents" do
      @person.tasks.keys.should_receive(:include?).with(@task.key).and_return(true)
      @person.tasks.include?(@task).should be_true
    end

    it "short-circuits and returns false if the given object is not a ripple document" do
      @person.tasks.keys.should_not_receive(:include?)
      @person.tasks.include?(Object.new).should be_false
    end

    it "returns false if the document's bucket is different from the associations bucket, even if the keys are the same" do
      @person.tasks << @task
      other_person = Person.new { |p| p.key = @task.key }
      @person.tasks.include?(other_person).should be_false
    end
  end
end
