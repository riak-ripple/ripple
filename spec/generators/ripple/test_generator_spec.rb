require 'spec_helper'
require 'rails/generators/ripple/test/test_generator'

describe Ripple::Generators::TestGenerator do
  context "when Cucumber is present" do
    before { mkdir_p file('features/support') }
    before { run_generator }

    it "should create a support file for the test server" do
      file('features/support/ripple.rb').should exist
    end
  end

  context "when RSpec is present" do
    let(:original_contents) do
      [
       "require 'rspec'",
       "RSpec.configure do |config|",
       "  config.mock_with :rspec",
       "end"
      ]
    end
    let(:helper) { file('spec/spec_helper.rb') }
    let(:contents) { File.read(helper) }
    before do
      mkdir_p file('spec')
      File.open(helper,'w') do |f|
        f.write original_contents.join("\n")
      end
      run_generator
    end

    it "should insert the test server require" do
      contents.should include("require 'ripple/test_server'")
    end

    it "should insert the test server setup" do
      contents.should include("  config.before(:suite) { Ripple::TestServer.setup }")
      contents.should include("  config.after(:each) { Ripple::TestServer.clear }")
      contents.should include("  config.after(:suite) { Ripple::TestServer.instance.stop }")
    end

    context "when the configuration block is indented" do
      let(:original_contents) do
        [
         "require 'rspec'",
         "require 'spork'",
         "Spork.prefork do",
         "  RSpec.configure do |config|",
         "    config.mock_with :rspec",
         "  end",
         "end"
        ]
      end

      it "should insert the test server require with additional indentation" do
        contents.should include("  require 'ripple/test_server'")
      end

      it "should insert the test server setup with additional indentation" do
        contents.should include("    config.before(:suite) { Ripple::TestServer.setup }")
        contents.should include("    config.after(:each) { Ripple::TestServer.clear }")
        contents.should include("    config.after(:suite) { Ripple::TestServer.instance.stop }")
      end
    end
  end

  context "when Test::Unit is present" do
    let(:original_contents) do
      [
       "require 'active_support/test_case'",
       "class ActiveSupport::TestCase",
       "  setup :load_fixtures",
       "end"
      ]
    end
    let(:helper) { file('test/test_helper.rb') }
    let(:contents) { File.read(helper) }
    before do
      mkdir_p file('test')
      File.open(helper,'w') do |f|
        f.write original_contents.join("\n")
      end
      run_generator
    end

    it "should insert the test server require" do
      contents.should include("require 'ripple/test_server'")
    end

    it "should insert the test server setup and teardown" do
      contents.should include("  setup { Ripple::TestServer.setup }")
      contents.should include("  teardown { Ripple::TestServer.clear }")
    end

    context "when the test case class is indented" do
      let(:original_contents) do
        [
         "require 'active_support/test_case'",
         "module MyApp",
         "  class ActiveSupport::TestCase",
         "    setup :load_fixtures",
         "  end",
         "end"
        ]
      end

      it "should insert the test server require with additional indentation" do
        contents.should include("  require 'ripple/test_server'")
      end

      it "should insert the test server setup and teardown with additional indentation" do
        contents.should include("    setup { Ripple::TestServer.setup }")
        contents.should include("    teardown { Ripple::TestServer.clear }")
      end
    end
  end
end
