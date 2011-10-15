require 'spec_helper'
require 'riak/node'
require 'yaml'

describe Riak::Node, :test_server => false, :slow => true do
  let(:test_server_config){ YAML.load_file("spec/support/test_server.yml") }
  subject { described_class.new(:root => ".ripplenode", :source => test_server_config['source']) }
  after { subject.stop if subject.started? }
  after(:all) { subject.destroy }
  
  context "creation" do
    before { subject.create }
    after { subject.destroy }

    describe "finding the base_dir and version" do
      it "should return a valid directory for base_dir" do
        subject.base_dir.should be_exist
      end

      it "should read a version from the releases directory" do
        subject.version.should match /\d+.\d+.\d+/
      end

      it "should return nil for base_dir if RUNNER_BASE_DIR is not found" do
        Pathname.any_instance.stub(:readlines).and_return([])
        subject.base_dir.should be_nil
      end

      it "should return nil for version if base_dir is nil" do
        Pathname.any_instance.stub(:readlines).and_return([])
        subject.version.should be_nil
      end
    end

    describe "generating the manifest" do
      it "should store the configuration manifest in the node directory" do
        (subject.root + '.node.yml').should be_exist
      end
    end

    describe "generating app.config" do
      let(:file) { subject.etc + 'app.config'}
      let(:contents) { file.read }

      it "should create the app.config file in the node directory" do
        file.should be_exist
      end

      it "should generate a correct Erlang configuration" do
        contents.should =~ /\A\[.*\]\.\Z/m
      end

      it "should set the ports starting from the given port" do
        contents.should include('{http, [{"127.0.0.1", 8080}]}')
        contents.should include('{pb_port, 8081}')
        contents.should include('{handoff_port, 8082}')
      end

      it "should set the ring directory to point to the node directory" do
        contents.should include("{ring_state_dir, \"#{subject.root + 'ring'}\"}")
      end
    end

    describe "generating vm.args" do
      let(:file){ subject.etc + 'vm.args' }
      let(:contents) { file.read }

      it "should create the vm.args file in the node directory" do
        file.should be_exist
      end

      it "should set a quasi-random node name by default" do
        contents.should match(/-name riak\d+@127\.0\.0\.1/)
      end

      it "should set a quasi-random cookie by default" do
        contents.should match(/-setcookie \d+_\d+/)
      end
    end

    describe "generating the start script" do
      let(:file) { subject.control_script }
      let(:contents) { file.read }

      it "should create the script in the node directory" do
        file.should be_exist
      end

      it "should modify the RUNNER_SCRIPT_DIR to point to the node directory" do
        contents.should match(/RUNNER_SCRIPT_DIR=#{subject.bin.to_s}/)
      end

      it "should modify the RUNNER_ETC_DIR to point to the node directory" do
        contents.should match(/RUNNER_ETC_DIR=#{subject.etc.to_s}/)
      end

      it "should modify the RUNNER_USER to point to none" do
        contents.should match(/RUNNER_USER=$/)
      end

      it "should modify the RUNNER_LOG_DIR to point to the node directory" do
        contents.should match(/RUNNER_LOG_DIR=#{subject.log.to_s}/)
      end

      it "should modify the RUNNER_BASE_DIR so that it is not relative" do
        contents.should_not match(/RUNNER_BASE_DIR=\$\{RUNNER_SCRIPT_DIR%\/\*\}/)
        contents.should match(/RUNNER_BASE_DIR=(.*)/) do |path|
          path.strip.should == subject.root.to_s
        end
      end

      it "should modify the PIPE_DIR to point to the node directory" do
        contents.should match(/PIPE_DIR=#{subject.pipe.to_s}\/?/)
      end
    end
  end

  context "destroying" do
    before { subject.create; subject.destroy }

    it "should remove the node directory and all its contents" do
      subject.root.should_not be_exist
    end
  end

  context "dropping data" do
    before do
      subject.create
      subject.start # Make it create some data directories
      subject.with_console do |console|
        # Write a ringfile
        console.command "riak_core_ring_manager:write_ringfile()."
      end
      # Don't restart the node after dropping so we can see the handiwork
      subject.stop
      subject.drop
    end

    it "should remove all data from the node" do
      (subject.root + 'data').children.map {|dir| dir.children }.flatten.should be_empty
    end

    it "should not remove the ring" do
      (subject.root + 'ring').children.should_not be_empty
    end
  end

  context "starting" do
    before { subject.create; subject.start }
    it { should be_started }
    after { subject.stop }
  end

  context "stopping" do
    before { subject.create; subject.start; subject.stop }
    it { should be_stopped }
  end

  context "attaching" do
    before { subject.create; subject.start }

    it "should attach to the running node" do
      console = subject.attach
      console.should be_kind_of(Riak::Node::Console)
      expect {
        console.command "ok."
        console.close
      }.should_not raise_error
    end
  end

  context "running" do
    before { subject.create; subject.start; subject.stop }

    it "should read the console log" do
      if subject.version >= "1.0.0"
        subject.read_console_log(:debug, :info, :notice).should_not be_empty
        subject.read_console_log(:debug..:emergency).should_not be_empty
        subject.read_console_log(:info).should_not be_empty
        subject.read_console_log(:foo).should be_empty
      end
    end
  end
end
