require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class TestGenerator < Base
      desc 'Generates test helpers for Ripple. Test::Unit, RSpec and Cucumber are supported.'
      # Cucumber
      def create_cucumber_file
        if File.directory?(Rails.root + "features/support")
          insert_into_file 'features/support/ripple.rb', "\n\nAfter do\n  Ripple::TestServer.clear\nend", :after => "Ripple::TestServer.setup"
        end
      end

      # RSpec
      def create_rspec_file
        if File.file?(Rails.root + 'spec/spec_helper.rb')
          inject_into_file 'spec/spec_helper.rb', :before => /R[Ss]pec\.configure do \|config\|/ do
            "require 'ripple/test_server'\n"
          end
          inject_into_file 'spec/spec_helper.rb', :after => /R[Ss]pec\.configure do \|config\|/ do
            "\n  config.before(:all){ Ripple::TestServer.setup }" +
            "\n  config.after(:each){ Ripple::TestServer.clear }\n"
          end
        end
      end

      # Test::Unit
      def create_test_unit_file
        if File.file?(Rails.root + 'test/test_helper.rb')
          inject_into_file "test/test_helper.rb", :before => "class ActiveSupport::TestCase" do
            "# Setup in-memory test server for Riak\nrequire 'ripple/test_server'\n\n"
          end
          inject_into_class "test/test_helper.rb", ActiveSupport::TestCase do
            "  setup { Ripple::TestServer.setup }\n  teardown { Ripple::TestServer.clear }\n\n"
          end
        end
      end
    end
  end
end
