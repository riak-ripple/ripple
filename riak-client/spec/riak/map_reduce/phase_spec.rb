require 'spec_helper'

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

        it "should include the function name when the function is not a lambda" do
          @phase.function = "Riak.mapValues"
          @phase.to_json.should include('"name":"Riak.mapValues"')
          @phase.to_json.should_not include('"source"')
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
