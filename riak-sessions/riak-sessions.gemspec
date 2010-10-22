# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{riak-sessions}
  s.version = "0.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sean Cribbs"]
  s.date = %q{2010-10-22}
  s.description = %q{riak-sessions is a session store backed by Riak, the distributed database by Basho. It includes session implementations for both Rack and Rails 3.}
  s.email = %q{seancribbs@gmail.com}
  s.files = ["lib/riak/session_store.rb", "lib/riak-sessions.rb", "lib/ripple/session_store.rb", "Rakefile", "spec/fixtures/session_autoload_test/session_autoload_test/foo.rb", "spec/riak_session_store_spec.rb", "spec/ripple_session_store_spec.rb", "spec/spec_helper.rb", "spec/support/ripple_session_support.rb", "spec/support/rspec-rails-neuter.rb", "spec/support/test_server.rb"]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{riak-sessions is a session store backed by Riak, the distributed database by Basho.}
  s.test_files = ["spec/fixtures/session_autoload_test/session_autoload_test/foo.rb", "spec/riak_session_store_spec.rb", "spec/ripple_session_store_spec.rb", "spec/spec_helper.rb", "spec/support/ripple_session_support.rb", "spec/support/rspec-rails-neuter.rb", "spec/support/test_server.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.0.0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.0.0"])
      s.add_development_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_development_dependency(%q<rails>, ["~> 3.0.0"])
      s.add_development_dependency(%q<curb>, ["> 0.6"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<riak-client>, ["~> 0.8.2"])
      s.add_runtime_dependency(%q<rack>, [">= 1.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.0.0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.0.0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<rails>, ["~> 3.0.0"])
      s.add_dependency(%q<curb>, ["> 0.6"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<riak-client>, ["~> 0.8.2"])
      s.add_dependency(%q<rack>, [">= 1.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.0.0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.0.0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<rails>, ["~> 3.0.0"])
    s.add_dependency(%q<curb>, ["> 0.6"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<riak-client>, ["~> 0.8.2"])
    s.add_dependency(%q<rack>, [">= 1.0"])
  end
end
