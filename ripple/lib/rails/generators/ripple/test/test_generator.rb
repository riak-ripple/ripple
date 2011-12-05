require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class TestGenerator < Base
      desc 'Generates test helpers for Ripple. Test::Unit, RSpec and Cucumber are supported.'
      # Cucumber
      def create_cucumber_file
        if File.directory?(Rails.root + "features/support")
          template 'test_server.rb', 'features/support/ripple.rb'
        end
      end

      # RSpec
      def create_rspec_file
        if File.file?(Rails.root + 'spec/spec_helper.rb')
          inject_into_file 'spec/spec_helper.rb', :before => /(\s*)R[Ss]pec\.configure do \|config\|/ do
            "#{$1}require 'ripple/test_server'\n"
          end
          inject_into_file 'spec/spec_helper.rb', :after => /(\s*)R[Ss]pec\.configure do \|config\|/ do
            "\n#{$1}  config.before(:all){ Ripple::TestServer.setup }" +
            "\n#{$1}  config.after(:each){ Ripple::TestServer.clear }\n"
          end
        end
      end

      # Test::Unit
      def create_test_unit_file
        if File.file?(Rails.root + 'test/test_helper.rb')
          inject_into_file "test/test_helper.rb", :before => /(\s*)class ActiveSupport::TestCase/ do
            "#{$1}# Setup in-memory test server for Riak\n#{$1}require 'ripple/test_server'\n\n"
          end
          inject_into_class "test/test_helper.rb", ActiveSupport::TestCase do
            "  setup { Ripple::TestServer.setup }\n  teardown { Ripple::TestServer.clear }\n\n"
          end
        end
      end
    end
  end
end
