require File.expand_path("spec_helper", File.dirname(__FILE__))

describe Riak::MapReduce do
  before :each do
    @client = Riak::Client.new
    @http = mock("HTTPClient")
    @client.stub!(:http).and_return(@http)
    @mr = Riak::MapReduce.new(@client)
  end

  it "should require a client" do
    lambda { Riak::MapReduce.new }.should raise_error
    lambda { Riak::MapReduce.new(@client) }.should_not raise_error
  end

  it "should initialize the inputs and query to empty arrays" do
    @mr.inputs.should == []
    @mr.query.should == []
  end

  it "should yield itself when given a block on initializing" do
    @mr2 = nil
    @mr = Riak::MapReduce.new(@client) do |mr|
      @mr2 = mr
    end
    @mr2.should == @mr
  end

  describe "adding inputs" do
    it "should return self for chaining" do
      @mr.add("foo", "bar").should == @mr
    end

    it "should add bucket/key pairs to the inputs" do
      @mr.add("foo","bar")
      @mr.inputs.should == [["foo","bar"]]
    end

    it "should add an array containing a bucket/key pair to the inputs" do
      @mr.add(["foo","bar"])
      @mr.inputs.should == [["foo","bar"]]
    end

    it "should add an object to the inputs by its bucket and key" do
      bucket = Riak::Bucket.new(@client, "foo")
      obj = Riak::RObject.new(bucket, "bar")
      @mr.add(obj)
      @mr.inputs.should == [["foo", "bar"]]
    end

    it "should add an array containing a bucket/key/key-data triple to the inputs" do
      @mr.add(["foo","bar",1000])
      @mr.inputs.should == [["foo","bar",1000]]
    end

    it "should use a bucket name as the single input" do
      @mr.add(Riak::Bucket.new(@client, "foo"))
      @mr.inputs.should == "foo"
      @mr.add("docs")
      @mr.inputs.should == "docs"
    end
  end

  [:map, :reduce].each do |type|
    describe "adding #{type} phases" do
      it "should return self for chaining" do
        @mr.send(type, "function(){}").should == @mr
      end

      it "should accept a function string" do
        @mr.send(type, "function(){}")
        @mr.query.should have(1).items
        phase = @mr.query.first
        phase.function.should == "function(){}"
        phase.type.should == type
      end

      it "should accept a function and options" do
        @mr.send(type, "function(){}", :keep => true)
        @mr.query.should have(1).items
        phase = @mr.query.first
        phase.function.should == "function(){}"
        phase.type.should == type
        phase.keep.should be_true
      end

      it "should accept a module/function pair" do
        @mr.send(type, ["riak","mapsomething"])
        @mr.query.should have(1).items
        phase = @mr.query.first
        phase.function.should == ["riak", "mapsomething"]
        phase.type.should == type
        phase.language.should == "erlang"
      end

      it "should accept a module/function pair with extra options" do
        @mr.send(type, ["riak", "mapsomething"], :arg => [1000])
        @mr.query.should have(1).items
        phase = @mr.query.first
        phase.function.should == ["riak", "mapsomething"]
        phase.type.should == type
        phase.language.should == "erlang"
        phase.arg.should == [1000]
      end
    end
  end

  describe "adding link phases" do
    it "should return self for chaining" do
      @mr.link({}).should == @mr
    end

    it "should accept a WalkSpec" do
      @mr.link(Riak::WalkSpec.new(:tag => "next"))
      @mr.query.should have(1).items
      phase = @mr.query.first
      phase.type.should == :link
      phase.function.should be_kind_of(Riak::WalkSpec)
      phase.function.tag.should == "next"
    end

    it "should accept a WalkSpec and a hash of options" do
      @mr.link(Riak::WalkSpec.new(:bucket => "foo"), :keep => true)
      @mr.query.should have(1).items
      phase = @mr.query.first
      phase.type.should == :link
      phase.function.should be_kind_of(Riak::WalkSpec)
      phase.function.bucket.should == "foo"
      phase.keep.should be_true
    end
    
    it "should accept a hash of options intermingled with the walk spec options" do
      @mr.link(:tag => "snakes", :arg => [1000])
      @mr.query.should have(1).items
      phase = @mr.query.first
      phase.arg.should == [1000]
      phase.function.should be_kind_of(Riak::WalkSpec)
      phase.function.tag.should == "snakes"
    end
  end

  describe "converting to JSON for the job" do    
    it "should include the inputs and query keys" do
      @mr.to_json.should =~ /"inputs":/
    end

    it "should map phases to their JSON equivalents" do
      phase = Riak::MapReduce::Phase.new(:type => :map, :function => "function(){}")
      @mr.query << phase
      @mr.to_json.should include('"source":"function(){}"')
      @mr.to_json.should include('"query":[{"map":{')
    end

    it "should emit only the bucket name when the input is the whole bucket" do
      @mr.add("foo")
      @mr.to_json.should include('"inputs":"foo"')
    end

    it "should emit an array of inputs when there are multiple inputs" do
      @mr.add("foo","bar",1000).add("foo","baz")
      @mr.to_json.should include('"inputs":[["foo","bar",1000],["foo","baz"]]')
    end
  end
end

describe Riak::MapReduce::Phase do
  before :each do
    @fun = "function(v,_,_){ return v['values'][0]['data']; }"
  end

  it "should initialize with a type and a function" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => @fun, :language => "javascript")
    phase.type.should == :map
    phase.function.should == @fun
    phase.language.should == "javascript"
  end

  it "should initialize with a type and an MF" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => ["module", "function"], :language => "erlang")
    phase.type.should == :map
    phase.function.should == ["module", "function"]
    phase.language.should == "erlang"
  end

  it "should initialize with a type and a bucket/key" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => {:bucket => "funs", :key => "awesome_map"}, :language => "javascript")
    phase.type.should == :map
    phase.function.should == {:bucket => "funs", :key => "awesome_map"}
    phase.language.should == "javascript"
  end

  it "should assume the language is erlang when the function is an array" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => ["module", "function"])
    phase.language.should == "erlang"
  end

  it "should assume the language is javascript when the function is a string" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => @fun)
    phase.language.should == "javascript"
  end

  it "should assume the language is javascript when the function is a hash" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => {:bucket => "jobs", :key => "awesome_map"})
    phase.language.should == "javascript"
  end
  
  it "should accept a WalkSpec for the function when a link phase" do
    phase = Riak::MapReduce::Phase.new(:type => :link, :function => Riak::WalkSpec.new({}))
    phase.function.should be_kind_of(Riak::WalkSpec)
  end

  it "should raise an error if a WalkSpec is given for a phase type other than :link" do
    lambda { Riak::MapReduce::Phase.new(:type => :map, :function => Riak::WalkSpec.new({})) }.should raise_error(ArgumentError)
  end
  
  describe "converting to JSON for the job" do
    before :each do
      @phase = Riak::MapReduce::Phase.new(:type => :map, :function => "")
    end

    [:map, :reduce].each do |type|
      describe "when a #{type} phase" do
        before :each do
          @phase.type = type
        end

        it "should be an object with a single key of '#{type}'" do
          @phase.to_json.should =~ /^\{"#{type}":/
        end

        it "should include the language" do
          @phase.to_json.should =~ /"language":/
        end

        it "should include the keep value" do
          @phase.to_json.should =~ /"keep":false/
          @phase.keep = true
          @phase.to_json.should =~ /"keep":true/
        end

        it "should include the function source when the function is a source string" do
          @phase.function = "function(v,_,_){ return v; }"
          @phase.to_json.should include(@phase.function)
          @phase.to_json.should =~ /"source":/
        end

        it "should include the bucket and key when referring to a stored function" do
          @phase.function = {:bucket => "design", :key => "wordcount_map"}
          @phase.to_json.should include('"bucket":"design"')
          @phase.to_json.should include('"key":"wordcount_map"')
        end

        it "should include the module and function when invoking an Erlang function" do
          @phase.function = ["riak_mapreduce", "mapreduce_fun"]
          @phase.to_json.should include('"module":"riak_mapreduce"')
          @phase.to_json.should include('"function":"mapreduce_fun"')
        end
      end
    end

    describe "when a link phase" do
      before :each do
        @phase.type = :link
        @phase.function = {}
      end

      it "should be an object of a single key 'link'" do
        @phase.to_json.should =~ /^\{"link":/
      end

      it "should include the bucket" do
        @phase.to_json.should =~ /"bucket":"_"/
        @phase.function[:bucket] = "foo"
        @phase.to_json.should =~ /"bucket":"foo"/
      end

      it "should include the tag" do
        @phase.to_json.should =~ /"tag":"_"/
        @phase.function[:tag] = "parent"
        @phase.to_json.should =~ /"tag":"parent"/
      end

      it "should include the keep value" do
        @phase.to_json.should =~ /"keep":false/
        @phase.keep = true
        @phase.to_json.should =~ /"keep":true/
        @phase.keep = false
        @phase.function[:keep] = true
        @phase.to_json.should =~ /"keep":true/
      end
    end
  end
end
