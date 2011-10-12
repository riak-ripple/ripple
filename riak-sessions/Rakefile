require 'rubygems'
require 'rubygems/package_task'
require 'rspec/core'
require 'rspec/core/rake_task'

def gemspec
  $riaksessions_gemspec ||= Gem::Specification.load("riak-sessions.gemspec")
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

task :gem => :gemspec

desc %{Validate the gemspec file.}
task :gemspec do
  gemspec.validate
end

desc %{Release the gem to RubyGems.org}
task :release => :gem do
  system "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem"
end

desc "Run Specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = %w[--profile]
end

task :default => :spec
