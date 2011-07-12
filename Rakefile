require 'rubygems'
require 'rake'
require 'rake/clean'

PROJECTS = %w{riak-client ripple riak-sessions}

begin
  require 'yard'
  desc "Generate YARD documentation."
  YARD::Rake::YardocTask.new do |yard|
    docfiles = FileList['{riak-client,ripple,riak-sessions}/lib/**/*.rb']
    docfiles.exclude '**/generators/**/templates/*'
    yard.files = docfiles.to_a + ['-','RELEASE_NOTES.textile']
    yard.options = ["--no-private"]
  end

  desc "Generate YARD documentation into a repo on the gh-pages branch."
  task :doc => :yard do
    original_dir = Dir.pwd
    docs_dir = File.expand_path(File.join(original_dir, "..", "ripple-docs"))
    rm_rf File.join(docs_dir, "*")
    cp_r File.join(original_dir, "doc", "."), docs_dir
    touch File.join(docs_dir, '.nojekyll')
  end
rescue LoadError, NameError
end

namespace :spec do
  PROJECTS.each do |dir|
    desc "Run specs for sub-project #{dir}."
    task dir do
      Dir.chdir(dir) do
        system 'rake spec'
      end
    end
  end

  desc "Run integration specs for all sub-projects."
  task :integration do
    %w{riak-client ripple}.each do |dir|
      Dir.chdir(dir) do
        system 'rake spec:integration'
      end
    end
  end
end

desc "Regenerate all gemspecs."
task :gemspecs do
  PROJECTS.each do |dir|
    Dir.chdir(dir) do
      system "rake gemspec"
    end
  end
end

desc "Release all gems to Rubygems.org."
task :release do
  PROJECTS.each do |dir|
    Dir.chdir(dir) do
      system "rake release"
    end
  end
end

desc "Cleans up white space for each project"
task :clean_whitespace do
  PROJECTS.each do |dir|
    Dir.chdir(dir) do
      no_file_cleaned = true
      puts
      puts ("=" * 20) + " #{dir} " + ("=" * 20)

      Dir["**/*.rb"].each do |file|
        contents = File.read(file)
        cleaned_contents = contents.gsub(/([ \t]+)$/, '')

        unless cleaned_contents == contents
          no_file_cleaned = false
          puts " - Cleaned #{file}"
          File.open(file, 'w') { |f| f.write(cleaned_contents) }
        end
      end

      if no_file_cleaned
        puts "No files with trailing whitespace found"
      end
    end
  end
end

desc "Run all sub-project specs."
task :spec => ["spec:riak-client", "spec:ripple", "spec:riak-sessions"]

task :default => :spec

CLOBBER.include(".yardoc")
CLOBBER.include("doc")
