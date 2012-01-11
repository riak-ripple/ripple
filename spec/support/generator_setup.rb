module GeneratorSetup
  def self.included(group)
    group.destination File.expand_path(File.join('..','..','..','tmp'), __FILE__)
    group.send :include, FileUtils
    group.before(:each){ Dir.chdir destination_root }
  end
end

RSpec.configure do |config|
  config.include GeneratorSetup, :type => :generator
end
