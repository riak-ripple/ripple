require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ripple"
    gem.summary = %Q{ripple is a simple Ruby client/wrapper for Riak, Basho's distributed database.}
    gem.description = %Q{ripple is a simple Ruby client for Riak, Basho's distributed database. It interacts with Riak via the "jiak" HTTP/JSON interface and models elements of the Riak database as Ruby objects.}
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
    gem.requirements << "curb gem for better performance"
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
  commit = `git log --pretty=oneline -1`
  chdir "../ripple-docs/" do
    system "rm -rf *"
    system "cp -r #{original_dir}/doc/* ."
    system "git add .; git add -u"
    system "git commit -m 'Update docs from commit: #{commit}'"
    system "git push origin gh-pages"
  end
end
