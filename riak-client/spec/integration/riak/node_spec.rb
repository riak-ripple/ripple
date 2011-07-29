require 'spec_helper'
require 'riak/node'

describe Riak::Node, :focus => true do
  subject { described_class.new(:root => ".riaktest") }
  
  context "creation" do
    before { subject.create }

    describe "generating the manifest" do
      it "should store the configuration manifest in the node directory"
    end

    describe "generating app.config" do
      it "should create the app.config file in the node directory"
      it "should generate a correct Erlang configuration"
      it "should set the ports starting from the given port"
      it "should set the ring directory to point to the node directory"
    end

    describe "generating vm.args" do
      it "should create the vm.args file in the node directory"
      it "should set a quasi-random node name by default"
      it "should set a quasi-random cookie by default"
    end

    describe "generating the start script" do
      it "should create the script in the node directory"
      it "should modify the RUNNER_SCRIPT_DIR to point to the node directory"
      it "should modify the RUNNER_ETC_DIR to point to the node directory"
      it "should modify the RUNNER_USER to point to the current user"
      it "should modify the RUNNER_LOG_DIR to point to the node directory"
      it "should modify the RUNNER_BASE_DIR so that it is not relative"
      it "should modify the PIPE_DIR to point to the node directory"
    end
  end

  context "destroying" do
    before { subject.create; subject.destroy }
    
    it "should remove the node directory and all its contents" do
      File.should_not be_exist(subject.root)
    end
  end

  context "dropping data" do
    it "should remove all data from the node"
    it "should not remove the ring"
  end

  context "starting" do
    before { subject.create; subject.start }
    it { should be_started }
  end

  context "stopping" do
    before { subject.create; subject.stop }
    it { should be_stopped }
  end

  context "attaching" do
    it "should attach to the running node"
  end
end
