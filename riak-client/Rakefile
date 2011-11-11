require 'rubygems'
require 'rubygems/package_task'
require 'rspec/core'
require 'rspec/core/rake_task'

def gemspec
  $riakclient_gemspec ||= Gem::Specification.load("riak-client.gemspec")
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

desc "Run Unit Specs Only"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = %w[--profile --tag ~integration --tag ~slow]
end

namespace :spec do
  desc "Run Integration Specs Only (without explicitly slow specs)"
  RSpec::Core::RakeTask.new(:integration) do |spec|
    spec.rspec_opts = %w[--profile --tag '~slow' --tag integration]
  end

  desc "Run All Specs (without explicitly slow specs)"
  RSpec::Core::RakeTask.new(:all) do |spec|
    spec.rspec_opts = %w[--profile --tag '~slow']
  end
end

desc "Run All Specs (including slow specs)"
RSpec::Core::RakeTask.new(:ci) do |spec|
  spec.rspec_opts = %w[--profile]
end

task :default => :ci
