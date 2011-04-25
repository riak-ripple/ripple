require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class TestGenerator < Base
      desc 'Generates test helpers for Ripple. Test::Unit, RSpec and Cucumber are supported.'
      # Cucumber
      def create_cucumber_file
        if File.directory?(Rails.root + "features/support")
          template 'test_server.rb', 'features/support/ripple.rb'
          insert_into_file 'features/support/ripple.rb', "\n\nAfter do\n  Ripple::TestServer.clear\nend", :after => "Ripple::TestServer.setup"
        end
      end

      # RSpec
      def create_rspec_file
        if File.file?(Rails.root + 'spec/spec_helper.rb')
          template 'test_server.rb', 'spec/support/ripple.rb'
          inject_into_file 'spec/spec_helper.rb', :after => /R[Ss]pec\.configure do \|config\|/ do
            "\n  config.after(:each) do\n    Ripple::TestServer.clear\n  end\n"
          end
        end
      end

      # Test::Unit
      def create_test_unit_file
        if File.file?(Rails.root + 'test/test_helper.rb')
          template 'test_server.rb', 'test/ripple_test_helper.rb'
          inject_into_file "test/test_helper.rb", :before => "class ActiveSupport::TestCase" do
            "# Setup in-memory test server for Riak\nrequire File.expand_path('../ripple_test_helper.rb', __FILE__)\n\n"
          end
          inject_into_class "test/test_helper.rb", ActiveSupport::TestCase do
            "  teardown { Ripple::TestServer.clear }\n\n"
          end
        end
      end
    end
  end
end
