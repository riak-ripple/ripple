require 'ammeter/init'
require 'fileutils'

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
