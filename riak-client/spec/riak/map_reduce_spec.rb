# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Riak::MapReduce do
  before :each do
    @client = Riak::Client.new
    @http = mock("HTTPBackend")
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

    it "should add bucket/key pairs to the inputs" do
      @mr.add("[foo]","(bar)")
      @mr.inputs.should == [["%5Bfoo%5D","%28bar%29"]]
    end

    it "should add an array containing a bucket/key pair to the inputs" do
      @mr.add(["foo","bar"])
      @mr.inputs.should == [["foo","bar"]]
    end

    it "should add an escaped array containing a bucket/key pair to the inputs" do
      @mr.add(["[foo]","(bar)"])
      @mr.inputs.should == [["%5Bfoo%5D","%28bar%29"]]
    end

    it "should add an object to the inputs by its bucket and key" do
      bucket = Riak::Bucket.new(@client, "foo")
      obj = Riak::RObject.new(bucket, "bar")
      @mr.add(obj)
      @mr.inputs.should == [["foo", "bar"]]
    end

    it "should add an object to the inputs by its escaped bucket and key" do
      bucket = Riak::Bucket.new(@client, "[foo]")
      obj = Riak::RObject.new(bucket, "(bar)")
      @mr.add(obj)
      @mr.inputs.should == [["%5Bfoo%5D", "%28bar%29"]]
    end

    it "should add an array containing a bucket/key/key-data triple to the inputs" do
      @mr.add(["foo","bar",1000])
      @mr.inputs.should == [["foo","bar",1000]]
    end

    it "should add an escaped array containing a bucket/key/key-data triple to the inputs" do
      @mr.add(["[foo]","(bar)","[]()"])
      @mr.inputs.should == [["%5Bfoo%5D", "%28bar%29","[]()"]]
    end

    it "should use a bucket name as the single input" do
      @mr.add(Riak::Bucket.new(@client, "foo"))
      @mr.inputs.should == "foo"
      @mr.add("docs")
      @mr.inputs.should == "docs"
    end

    it "should use an escaped bucket name as the single input" do
      @mr.add(Riak::Bucket.new(@client, "[foo]"))
      @mr.inputs.should == "%5Bfoo%5D"
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

    it "should add the timeout value when set" do
      @mr.timeout(50000)
      @mr.to_json.should include('"timeout":50000')
    end
  end

  it "should return self from setting the timeout" do
    @mr.timeout(5000).should == @mr
  end

  describe "executing the map reduce job" do
    before :each do
      @mr.map("Riak.mapValues",:keep => true)
    end

    it "should raise an exception when no phases are defined" do
      @mr.query.clear
      lambda { @mr.run }.should raise_error(Riak::MapReduceError)
    end

    it "should issue POST request to the mapred endpoint" do
      @http.should_receive(:post).with(200, "/mapred", @mr.to_json, hash_including("Content-Type" => "application/json")).and_return({:headers => {'content-type' => ["application/json"]}, :body => "[]"})
      @mr.run
    end

    it "should vivify JSON responses" do
      @http.stub!(:post).and_return(:headers => {'content-type' => ["application/json"]}, :body => '[{"key":"value"}]')
      @mr.run.should == [{"key" => "value"}]
    end

    it "should return the full response hash for non-JSON responses" do
      response = {:code => 200, :headers => {'content-type' => ["text/plain"]}, :body => 'This is some text.'}
      @http.stub!(:post).and_return(response)
      @mr.run.should == response
    end

    it "should interpret failed requests with JSON content-types as map reduce errors" do
      @http.stub!(:post).and_raise(Riak::FailedRequest.new(:post, 200, 500, {"content-type" => ["application/json"]}, '{"error":"syntax error"}'))
      lambda { @mr.run }.should raise_error(Riak::MapReduceError)
      begin
        @mr.run
      rescue Riak::MapReduceError => mre
        mre.message.should == '{"error":"syntax error"}'
      else
        fail "No exception raised!"
      end
    end

    it "should re-raise non-JSON error responses" do
      @http.stub!(:post).and_raise(Riak::FailedRequest.new(:post, 200, 500, {"content-type" => ["text/plain"]}, 'Oops, you bwoke it.'))
      lambda { @mr.run }.should raise_error(Riak::FailedRequest)
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
