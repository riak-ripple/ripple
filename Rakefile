require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "riak-client"
    gem.summary = %Q{riak-client is a simple Ruby client/wrapper for Riak, Basho's distributed database.}
    gem.description = %Q{riak-client is a simple Ruby client for Riak, Basho's distributed database. It interacts with Riak via the "jiak" HTTP/JSON interface and models elements of the Riak database as Ruby objects.}
    gem.email = "seancribbs@gmail.com"
    gem.homepage = "http://github.com/seancribbs/riak-client"
    gem.authors = ["Sean Cribbs"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "cucumber", ">= 0.4.0"
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

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "riak-client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
