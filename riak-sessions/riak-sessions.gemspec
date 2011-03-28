# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{riak-sessions}
  s.version = "0.9.0.beta2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sean Cribbs"]
  s.date = %q{2011-03-28}
  s.description = %q{riak-sessions is a session store backed by Riak, the distributed database by Basho. It includes session implementations for both Rack and Rails 3.}
  s.email = %q{sean@basho.com}
  s.files = ["Gemfile", "lib/riak/session_store.rb", "lib/riak-sessions.rb", "lib/ripple/session_store.rb", "Rakefile", "riak-sessions.gemspec", "spec/fixtures/session_autoload_test/session_autoload_test/foo.rb", "spec/riak_session_store_spec.rb", "spec/ripple_session_store_spec.rb", "spec/spec_helper.rb", "spec/support/ripple_session_support.rb", "spec/support/rspec-rails-neuter.rb", "spec/support/test_server.rb", "spec/support/test_server.yml.example"]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.1}
  s.summary = %q{riak-sessions is a session store backed by Riak, the distributed database by Basho.}
  s.test_files = ["spec/riak_session_store_spec.rb", "spec/ripple_session_store_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.4.0"])
      s.add_development_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_development_dependency(%q<rails>, ["~> 3.0.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<riak-client>, ["~> 0.9.0.beta2"])
      s.add_runtime_dependency(%q<rack>, [">= 1.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.4.0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<rails>, ["~> 3.0.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<riak-client>, ["~> 0.9.0.beta2"])
      s.add_dependency(%q<rack>, [">= 1.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.4.0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.4.0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<rails>, ["~> 3.0.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<riak-client>, ["~> 0.9.0.beta2"])
    s.add_dependency(%q<rack>, [">= 1.0"])
  end
end
