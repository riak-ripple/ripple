require 'ammeter/init'
require 'fileutils'

# Silences warnings on Rails 3.2 that are caused by ammeter. Remove
# when ammeter gem version is bumped. See commit:
# https://github.com/alexrothenberg/ammeter/commit/08e27fbcd2e710f2129f65e1dac1047eb70542ee
if Ammeter::RSpec::Rails::GeneratorExampleGroup.const_defined?(:InstanceMethods)
  module Ammeter::RSpec::Rails::GeneratorExampleGroup
     def invoke_task name
       capture(:stdout) { generator.invoke_task(generator_class.all_tasks[name.to_s]) }
     end
     remove_const :InstanceMethods
  end
end

module GeneratorSetup
  include FileUtils
  def self.included(group)
    group.destination File.expand_path(File.join('..','..','..','tmp'), __FILE__)
    group.before(:each){ Dir.chdir destination_root }
  end
end

RSpec.configure do |config|
  config.include GeneratorSetup, :type => :generator
end
