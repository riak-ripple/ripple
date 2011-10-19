require 'spec_helper'
require 'riak/cluster'

describe Riak::Cluster, :test_server => false, :slow => true do
  let(:config) { YAML.load_file("spec/support/test_server.yml").symbolize_keys }
  subject { described_class.new(config) }

  it "should have a list of nodes" do
    should respond_to(:nodes)
    subject.nodes.should be_kind_of(Array)
    subject.nodes.should have(4).items
    subject.nodes.should be_all {|n| n.kind_of?(Riak::Node) }
  end

  it "should have a configuration" do
    should respond_to(:configuration)
    subject.configuration.should be_kind_of(Hash)
  end

  it "should require a :source and :root configuration keys" do
    expect {
      described_class.new({})
    }.to raise_error(ArgumentError)
  end

  it "should not be created initially" do
    should_not be_exist
  end

  context "creating the cluster" do
    before { subject.create }
    after { subject.destroy }

    it "should generate all nodes inside its root" do
      subject.root.should be_exist
      subject.nodes.should be_all {|n| n.exist? }
    end
  end

  context "destroying the cluster" do
    before { subject.create; subject.should be_exist; subject.destroy }

    it "should remove all nodes and its root directory" do
      subject.should_not be_exist
    end
  end

  context "dropping data from the cluster" do
    it "should make all nodes drop their data" do
      subject.nodes.each {|n| n.should_receive(:drop) }
      subject.drop
    end
  end

  context "starting the cluster", :slow => true do
    before { subject.create }
    after { subject.destroy }

    it "should start all nodes in the cluster" do
      subject.start
      subject.nodes.should be_all {|n| n.started? }
    end
  end

  context "stopping the cluster", :slow => true do
    before { subject.create; subject.start; subject.should be_started }
    after { subject.destroy }

    it "should stop all nodes in the cluster" do
      subject.stop
      subject.nodes.should be_all {|n| n.stopped? }
    end
  end

  context "joining the cluster together", :slow => true do
    before { subject.create; subject.start; subject.should be_started }
    after { subject.destroy }

    it "should join nodes into a cluster" do
      subject.join
      node_names = subject.nodes.map {|n| n.name }.sort
      subject.nodes.should be_all do |n|
        n.peers.should have(3).items
        n.peers.sort == (node_names - [n.name])
      end
    end
  end
end
