
# Copied from rspec-rails but bypassing the part that requires a Rails
# app
module RSpec
  module Rails
    class << self
      def using_active_record?
        #::Rails.configuration.generators.options[:rails][:orm] ==
        #:active_record
        false
      end
    end
  end
end

require 'rspec/core'

RSpec::configure do |c|
  c.backtrace_clean_patterns << /vendor\//
  c.backtrace_clean_patterns << /lib\/rspec\/rails/
end

require 'rspec/rails/extensions'
require 'rspec/rails/view_rendering'
require 'rspec/rails/adapters'
require 'rspec/rails/matchers'
require 'rspec/rails/fixture_support'
require 'rspec/rails/mocks'
require 'rspec/rails/module_inclusion'
#require 'rspec/rails/browser_simulators'
require 'rspec/rails/example'
