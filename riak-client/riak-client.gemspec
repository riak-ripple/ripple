# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{riak-client}
  s.version = "0.9.0.beta2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sean Cribbs"]
  s.date = %q{2011-03-28}
  s.description = %q{riak-client is a rich client for Riak, the distributed database by Basho. It supports the full HTTP interface including storage operations, bucket configuration, link-walking and map-reduce.}
  s.email = %q{sean@basho.com}
  s.files = ["erl_src/riak_kv_test_backend.beam", "erl_src/riak_kv_test_backend.erl", "Gemfile", "lib/active_support/cache/riak_store.rb", "lib/riak/bucket.rb", "lib/riak/cache_store.rb", "lib/riak/client/beefcake/messages.rb", "lib/riak/client/beefcake/object_methods.rb", "lib/riak/client/beefcake_protobuffs_backend.rb", "lib/riak/client/curb_backend.rb", "lib/riak/client/excon_backend.rb", "lib/riak/client/http_backend/configuration.rb", "lib/riak/client/http_backend/object_methods.rb", "lib/riak/client/http_backend/request_headers.rb", "lib/riak/client/http_backend/transport_methods.rb", "lib/riak/client/http_backend.rb", "lib/riak/client/net_http_backend.rb", "lib/riak/client/protobuffs_backend.rb", "lib/riak/client/pump.rb", "lib/riak/client.rb", "lib/riak/core_ext/blank.rb", "lib/riak/core_ext/extract_options.rb", "lib/riak/core_ext/slice.rb", "lib/riak/core_ext/stringify_keys.rb", "lib/riak/core_ext/symbolize_keys.rb", "lib/riak/core_ext/to_param.rb", "lib/riak/core_ext.rb", "lib/riak/failed_request.rb", "lib/riak/i18n.rb", "lib/riak/invalid_response.rb", "lib/riak/link.rb", "lib/riak/locale/en.yml", "lib/riak/map_reduce/filter_builder.rb", "lib/riak/map_reduce/phase.rb", "lib/riak/map_reduce.rb", "lib/riak/map_reduce_error.rb", "lib/riak/robject.rb", "lib/riak/search.rb", "lib/riak/test_server.rb", "lib/riak/util/escape.rb", "lib/riak/util/fiber1.8.rb", "lib/riak/util/headers.rb", "lib/riak/util/multipart/stream_parser.rb", "lib/riak/util/multipart.rb", "lib/riak/util/tcp_socket_extensions.rb", "lib/riak/util/translation.rb", "lib/riak/walk_spec.rb", "lib/riak.rb", "Rakefile", "riak-client.gemspec", "spec/fixtures/cat.jpg", "spec/fixtures/multipart-blank.txt", "spec/fixtures/multipart-with-body.txt", "spec/fixtures/server.cert.crt", "spec/fixtures/server.cert.key", "spec/fixtures/test.pem", "spec/integration/riak/cache_store_spec.rb", "spec/integration/riak/http_backends_spec.rb", "spec/integration/riak/protobuffs_backends_spec.rb", "spec/integration/riak/test_server_spec.rb", "spec/riak/bucket_spec.rb", "spec/riak/client_spec.rb", "spec/riak/curb_backend_spec.rb", "spec/riak/escape_spec.rb", "spec/riak/excon_backend_spec.rb", "spec/riak/headers_spec.rb", "spec/riak/http_backend/configuration_spec.rb", "spec/riak/http_backend/object_methods_spec.rb", "spec/riak/http_backend/transport_methods_spec.rb", "spec/riak/http_backend_spec.rb", "spec/riak/link_spec.rb", "spec/riak/map_reduce/filter_builder_spec.rb", "spec/riak/map_reduce/phase_spec.rb", "spec/riak/map_reduce_spec.rb", "spec/riak/multipart_spec.rb", "spec/riak/net_http_backend_spec.rb", "spec/riak/robject_spec.rb", "spec/riak/search_spec.rb", "spec/riak/stream_parser_spec.rb", "spec/riak/walk_spec_spec.rb", "spec/spec_helper.rb", "spec/support/drb_mock_server.rb", "spec/support/http_backend_implementation_examples.rb", "spec/support/mock_server.rb", "spec/support/mocks.rb", "spec/support/test_server.yml.example", "spec/support/unified_backend_examples.rb"]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.1}
  s.summary = %q{riak-client is a rich client for Riak, the distributed database by Basho.}
  s.test_files = ["lib/riak/walk_spec.rb", "spec/integration/riak/cache_store_spec.rb", "spec/integration/riak/http_backends_spec.rb", "spec/integration/riak/protobuffs_backends_spec.rb", "spec/integration/riak/test_server_spec.rb", "spec/riak/bucket_spec.rb", "spec/riak/client_spec.rb", "spec/riak/curb_backend_spec.rb", "spec/riak/escape_spec.rb", "spec/riak/excon_backend_spec.rb", "spec/riak/headers_spec.rb", "spec/riak/http_backend/configuration_spec.rb", "spec/riak/http_backend/object_methods_spec.rb", "spec/riak/http_backend/transport_methods_spec.rb", "spec/riak/http_backend_spec.rb", "spec/riak/link_spec.rb", "spec/riak/map_reduce/filter_builder_spec.rb", "spec/riak/map_reduce/phase_spec.rb", "spec/riak/map_reduce_spec.rb", "spec/riak/multipart_spec.rb", "spec/riak/net_http_backend_spec.rb", "spec/riak/robject_spec.rb", "spec/riak/search_spec.rb", "spec/riak/stream_parser_spec.rb", "spec/riak/walk_spec_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_development_dependency(%q<fakeweb>, [">= 1.2"])
      s.add_development_dependency(%q<rack>, [">= 1.0"])
      s.add_development_dependency(%q<curb>, [">= 0.6"])
      s.add_development_dependency(%q<excon>, ["~> 0.5.7"])
      s.add_runtime_dependency(%q<i18n>, [">= 0.4.0"])
      s.add_runtime_dependency(%q<builder>, ["~> 2.1.2"])
      s.add_runtime_dependency(%q<beefcake>, ["~> 0.2.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_dependency(%q<fakeweb>, [">= 1.2"])
      s.add_dependency(%q<rack>, [">= 1.0"])
      s.add_dependency(%q<curb>, [">= 0.6"])
      s.add_dependency(%q<excon>, ["~> 0.5.7"])
      s.add_dependency(%q<i18n>, [">= 0.4.0"])
      s.add_dependency(%q<builder>, ["~> 2.1.2"])
      s.add_dependency(%q<beefcake>, ["~> 0.2.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.4.0"])
    s.add_dependency(%q<fakeweb>, [">= 1.2"])
    s.add_dependency(%q<rack>, [">= 1.0"])
    s.add_dependency(%q<curb>, [">= 0.6"])
    s.add_dependency(%q<excon>, ["~> 0.5.7"])
    s.add_dependency(%q<i18n>, [">= 0.4.0"])
    s.add_dependency(%q<builder>, ["~> 2.1.2"])
    s.add_dependency(%q<beefcake>, ["~> 0.2.0"])
  end
end
