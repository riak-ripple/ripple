$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'riak-client','lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'ripple'
require 'ripple/conflict/test_helper'
require 'rspec'
require 'ammeter'

# Only the tests should really get away with this.
Riak.disable_list_keys_warnings = true

%w[
   integration_setup
   generator_setup
   test_server
   search
   models
   associations
  ].each do |file|
  require File.join("support", file)
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  # config.debug = true
  config.include Ripple::Conflict::TestHelper

  if defined? Java
    config.seed = Time.now.to_i
  else
    config.order = :random
  end
end
