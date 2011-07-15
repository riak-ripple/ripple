require 'spec_helper'

describe Ripple::AttributeMethods do
  require 'support/models/widget'

  before :each do
    @widget = Widget.new
  end

  describe "object key" do
    it "should provide access to the key" do
      @widget.should respond_to(:key)
      @widget.key.should be_nil
    end

    it "should provide a mutator for the key" do
      @widget.should respond_to(:key=)
      @widget.key = "cog"
      @widget.key.should == "cog"
    end

    it "should not set the key from mass assignment" do
      @widget.key = 'widget-key'
      @widget.attributes = {'key' => 'new-key'}
      @widget.key.should == 'widget-key'
    end

    it "should typecast the key to a string" do
      @widget.key = 10
      @widget.key.should == "10"
    end
  end

  describe "accessors" do
    it "should be defined for defined properties" do
      @widget.should respond_to(:size)
      @widget.should respond_to(:name)
    end

    it "should return nil if no default is defined on the property" do
      @widget.size.should be_nil
    end

    it "should return the property default if defined and not set" do
      @widget.name.should == "widget"
      @widget.manufactured.should == false
    end

    it "dups the default if it is duplicable so that two document do not share the same mutable value" do
      widget2 = Widget.new
      @widget.name.should_not be(widget2.name)
      widget2.name.gsub!("w", "f")
      @widget.name.should == "widget"
    end

    it "should allow raw attribute access when accessing the document with []" do
      @widget['name'].should == 'widget'
    end

    it "should expose the property directly" do
      @widget.name.gsub!("w","f")
      @widget.name.should == "fidget"
    end
  end

  describe "mutators" do
    it "should have mutators for defined properties" do
      @widget.should respond_to(:size=)
      @widget.should respond_to(:name=)
    end

    it "should assign the value of the attribute" do
      @widget.size = 10
      @widget.size.should == 10
    end

    it "should allow assignment of undefined attributes when assigning to the document with []=" do
      @widget.should_not respond_to(:shoe_size)
      @widget['shoe_size'] = 8
      @widget['shoe_size'].should == 8
    end

    it "should type cast assigned values automatically" do
      @widget.name = :so_what
      @widget.name.should == "so_what"
    end

    it "should raise an error when assigning a bad value" do
      lambda { @widget.size = true }.should raise_error(Ripple::PropertyTypeMismatch)
    end
  end

  describe "query methods" do
    it "should be defined for defined properties" do
      @widget.should respond_to(:size?)
      @widget.should respond_to(:name?)
    end

    it "should be false when the attribute is nil" do
      @widget.size.should be_nil
      @widget.size?.should be_false
    end

    it "should be true when the attribute has a value present" do
      @widget.size = 10
      @widget.size?.should be_true
    end

    it "should be false for 0 values" do
      @widget.size = 0
      @widget.size?.should be_false
    end

    it "should be false for empty values" do
      @widget.name = ""
      @widget.name?.should be_false
    end
  end

  it "should track changes to attributes" do
    @widget.name = "foobar"
    @widget.changed?.should be_true
    @widget.name_changed?.should be_true
    @widget.name_change.should == ["widget", "foobar"]
    @widget.changes.should == {"name" => ["widget", "foobar"]}
  end

  it "should report that an attribute is changed only if its value actually changes" do
    @widget.name = "widget"
    @widget.changed?.should be_false
    @widget.name_changed?.should be_false
    @widget.changes.should be_blank
  end

  it "should refresh the attribute methods when adding a new property" do
    Widget.should_receive(:undefine_attribute_methods)
    Widget.property :start_date, Date
    Widget.properties.delete(:start_date) # cleanup
  end

  describe "#attributes" do
    it "it returns a hash representation of all of the attributes" do
      @widget.attributes.should == {"name" => "widget", "size" => nil, "manufactured" => false, "shipped_at" => nil}
    end

    it "does not include ghost attributes (attributes that do not have a defined property)" do
      @widget['some_undefined_prop'] = 3.14159
      @widget.attributes.should_not include('some_undefined_prop')
    end
  end

  describe "#raw_attributes" do
    it "returns a hash representation, including attributes for undefined properties" do
      @widget['some_undefined_prop'] = 17
      @widget.raw_attributes.should == {
        'name'                => 'widget',
        'size'                => nil,
        'manufactured'        => false,
        'shipped_at'          => nil,
        'some_undefined_prop' => 17
      }
    end
  end

  it "should load attributes from mass assignment" do
    @widget.attributes = {"name" => "Riak", "size" => 100000 }
    @widget.name.should == "Riak"
    @widget.size.should == 100000
  end

  it "should assign attributes on initialization" do
    @widget = Widget.new(:name => "Riak")
    @widget.name.should == "Riak"
  end

  it "should have no changed attributes after initialization" do
    @widget = Widget.new(:name => "Riak")
    @widget.changes.should be_blank
  end

  it "should allow adding to the @attributes hash for attributes that do not exist" do
    @widget = Widget.new
    @widget['foo'] = 'bar'
    @widget.instance_eval { @attributes['foo'] }.should == 'bar'
  end

  it "should allow reading from the @attributes hash for attributes that do not exist" do
    @widget = Widget.new
    @widget['foo'] = 'bar'
    @widget['foo'].should == 'bar'
  end

  it "should allow a block upon initialization to set attributes protected from mass assignment" do
    @widget = Widget.new { |w| w.key = 'some-key' }
    @widget.key.should == 'some-key'
  end

  it "should raise an argument error when assigning a non hash to attributes" do
    @widget = Widget.new
    lambda { @widget.attributes = nil }.should raise_error(ArgumentError)
  end

  it "should protect attributes from mass assignment when initialized" do
    @widget = Widget.new(:manufactured => true)
    @widget.manufactured.should be_false
  end

  it "should protect attributes from mass assignment by default" do
    @widget = Widget.new
    @widget.attributes = { :manufactured => true }
    @widget.manufactured.should be_false
  end

  it "should allow protected attributes to be mass assigned via raw_attributes=" do
    @widget = Widget.new
    @widget.send(:raw_attributes=, { :manufactured => true })
    @widget.manufactured.should be_true
  end

  it "should allow mass assigning arbitrary attributes via raw_attributes" do
    @widget = Widget.new
    @widget.__send__(:raw_attributes=, :explode => '?BOOM')
    @widget[:explode].should eq('?BOOM')
  end

  it "should raise an ArgumentError with an undefined property message when mass assigning a property that doesn't exist" do
    lambda { @widget = Widget.new(:explode => '?BOOM') }.should raise_error(ArgumentError, %q[Undefined property :explode for class 'Widget'])
  end

end
