require 'rubygems'
require 'rake'
require 'rake/clean'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ripple"
    gem.summary = %Q{ripple is a rich Ruby client for Riak, Basho's distributed database.}
    gem.description = %Q{ripple is a rich Ruby client for Riak, Basho's distributed database.  It includes all the basics of accessing and manipulating Riak buckets and objects, and an object mapper library for building a rich domain on top of Riak.}
    gem.email = "seancribbs@gmail.com"
    gem.homepage = "http://seancribbs.github.com/ripple"
    gem.authors = ["Sean Cribbs"]
    gem.add_development_dependency "rspec", "~>2.0.0.beta.5"
    gem.add_development_dependency "fakeweb", ">=1.2"
    gem.add_development_dependency "rack", ">=1.0"
    gem.add_development_dependency "yard", ">=0.5.2"
    gem.add_development_dependency "curb", ">=0.6"
    gem.add_dependency "activesupport", "3.0.0.beta2"
    gem.add_dependency "activemodel", "3.0.0.beta2"
    gem.requirements << "`gem install curb` for better HTTP performance"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run Unit Specs Only"
Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/{ripple,riak}/**/*_spec.rb"
end

namespace :spec do
  desc "Run Ripple Unit Specs Only"
  Rspec::Core::RakeTask.new(:ripple) do |spec|
    spec.pattern = "spec/ripple/**/*_spec.rb"
  end

  desc "Run Riak Unit Specs Only"
  Rspec::Core::RakeTask.new(:riak) do |spec|
    spec.pattern = "spec/riak/**/*_spec.rb"
  end

  desc "Run Integration Specs Only"
  Rspec::Core::RakeTask.new(:integration) do |spec|
    spec.pattern = "spec/integration/**/*_spec.rb"
  end

  desc "Run All Specs"
  Rspec::Core::RakeTask.new(:all) do |spec|
    spec.pattern = "spec/**/*_spec.rb"
  end
end


Rspec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = ['--exclude', 'lib\/spec,bin\/spec,config\/boot.rb,gems,spec_helper,spec']
end

task :rcovo => [:rcov] do
  system "open coverage/index.html"
end

task :spec => :check_dependencies

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new do |yard|
  docfiles = FileList['lib/**/*.rb', 'README*', 'VERSION', 'LICENSE', 'RELEASE_NOTES.textile']
  yard.files = docfiles
  yard.options = ["--no-private"]
end

task :doc => :yard do
  original_dir = Dir.pwd
  docs_dir = File.expand_path(File.join(original_dir, "..", "ripple-docs"))
  rm_rf File.join(docs_dir, "*")
  cp_r File.join(original_dir, "doc", "."), docs_dir
  touch File.join(docs_dir, '.nojekyll')
end

CLOBBER.include(".yardoc")
CLOBBER.include("doc")
