require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class TestGenerator < Base
      desc 'Generates test helpers for Ripple. Test::Unit, RSpec and Cucumber are supported.'
      # Cucumber
      def create_cucumber_file
        if File.directory?("features/support")
          template 'cucumber.rb.erb', 'features/support/ripple.rb'
        end
      end

      # RSpec
      def create_rspec_file
        if File.file?('spec/spec_helper.rb')
          rspec_prelude = /\s*R[Ss]pec\.configure do \|config\|/
          indentation = File.binread('spec/spec_helper.rb').match(rspec_prelude)[0].match(/^\s*/)[0]
          inject_into_file 'spec/spec_helper.rb', :before => rspec_prelude do
            "#{indentation}require 'ripple/test_server'\n"
          end
          inject_into_file 'spec/spec_helper.rb', :after => rspec_prelude do
            "\n#{indentation}  config.before(:suite) { Ripple::TestServer.setup }" +
              "\n#{indentation}  config.after(:each) { Ripple::TestServer.clear }\n"
          end
        end
      end

      # Test::Unit
      def create_test_unit_file
        if File.file?('test/test_helper.rb')
          test_case_prelude = /\s*class ActiveSupport::TestCase/
          indentation = File.binread('test/test_helper.rb').match(test_case_prelude)[0].match(/^\s*/)[0]
          inject_into_file "test/test_helper.rb", :before => test_case_prelude do
            "#{indentation}# Setup in-memory test server for Riak\n#{indentation}require 'ripple/test_server'\n\n"
          end
          inject_into_class "test/test_helper.rb", 'ActiveSupport::TestCase' do
            "#{indentation}  setup { Ripple::TestServer.setup }\n#{indentation}  teardown { Ripple::TestServer.clear }\n\n"
          end
        end
      end
    end
  end
end
