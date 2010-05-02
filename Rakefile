require 'rubygems'
require 'rake'
require 'rake/clean'

require 'yard'
YARD::Rake::YardocTask.new do |yard|
  docfiles = FileList['{riak,ripple}/lib/**/*.rb', 'README*','LICENSE', 'RELEASE_NOTES.textile']
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

namespace :spec do
  %w{riak ripple}.each do |dir|
    task dir do
      Dir.chdir(dir) do
        system 'rake spec'
      end
    end
  end
  
  task :integration do
    %w{riak ripple}.each do |dir|
      Dir.chdir(dir) do
        system 'rake spec:integration'
      end
    end
  end
end
  

task :spec => ["spec:riak", "spec:ripple"]

task :default => :spec

CLOBBER.include(".yardoc")
CLOBBER.include("doc")
