require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ripple"
    gem.summary = %Q{ripple is a simple Ruby client/wrapper for Riak, Basho's distributed database.}
    gem.description = %Q{ripple is a Ruby client for Riak, Basho's distributed database. It interacts with the "raw" HTTP interface to Riak, allowing storage of both traditional domain objects as JSON and other formats.}
    gem.email = "seancribbs@gmail.com"
    gem.homepage = "http://seancribbs.github.com/ripple"
    gem.authors = ["Sean Cribbs"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem.add_development_dependency "cucumber", ">= 0.4.0"
    gem.add_development_dependency "fakeweb", ">=1.2"
    gem.add_development_dependency "rack", ">=1.0"
    gem.add_development_dependency "yard", ">=0.5.2"
    gem.add_development_dependency "curb", ">=0.6"
    gem.add_dependency "activesupport", ">=2.3"
    gem.requirements << "`gem install curb` for better HTTP performance"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = ['--exclude', 'lib\/spec,bin\/spec,config\/boot.rb,gems,spec_helper']
end

task :spec => :check_dependencies

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new do |yard|
  docfiles = FileList['lib/**/*.rb', 'README*', 'VERSION', 'LICENSE']
  docfiles.exclude 'lib/ripple.rb'
  yard.files = docfiles
end

task :doc => :yard do
  original_dir = Dir.pwd
  docs_dir = File.expand_path(File.join(original_dir, "..", "ripple-docs"))
  commit = `git log --pretty=oneline -1`
  rm_rf File.join(docs_dir, "*")
  cp_r File.join(original_dir, "doc", "."), docs_dir
  touch File.join(docs_dir, '.nojekyll')
end
