$:.push File.expand_path("../lib", __FILE__)
require 'riak-sessions/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "riak-sessions"
  gem.summary = %Q{riak-sessions is a session store backed by Riak, the distributed database by Basho.}
  gem.description = %Q{riak-sessions is a session store backed by Riak, the distributed database by Basho. It includes session implementations for both Rack and Rails 3.}
  gem.version = Riak::Sessions::VERSION
  gem.email = ["sean@basho.com"]
  gem.homepage = "http://seancribbs.github.com/ripple"
  gem.authors = ["Sean Cribbs"]

  # Deps
  gem.add_development_dependency "rspec", "~>2.6.0"
  gem.add_development_dependency "rspec-rails", "~>2.6.0"
  gem.add_development_dependency "yajl-ruby"
  gem.add_development_dependency "rails", "~>3.0.0"
  gem.add_development_dependency "rake"
  gem.add_dependency "riak-client", "~>#{Riak::Sessions::VERSION}"
  gem.add_dependency "rack", ">=1.0"

  # Files
  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files = (Dir['spec/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  # gem.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  gem.require_paths = ['lib']
end
