# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{riak-client}
  s.version = "0.9.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Sean Cribbs}]
  s.date = %q{2011-07-26}
  s.description = %q{riak-client is a rich client for Riak, the distributed database by Basho. It supports the full HTTP interface including storage operations, bucket configuration, link-walking and map-reduce.}
  s.email = %q{sean@basho.com}
  s.files = [%q{erl_src/riak_kv_test_backend.beam}, %q{erl_src/riak_kv_test_backend.erl}, %q{Gemfile}, %q{lib/active_support/cache/riak_store.rb}, %q{lib/riak/bucket.rb}, %q{lib/riak/cache_store.rb}, %q{lib/riak/client/beefcake/messages.rb}, %q{lib/riak/client/beefcake/object_methods.rb}, %q{lib/riak/client/beefcake_protobuffs_backend.rb}, %q{lib/riak/client/curb_backend.rb}, %q{lib/riak/client/excon_backend.rb}, %q{lib/riak/client/http_backend/configuration.rb}, %q{lib/riak/client/http_backend/key_streamer.rb}, %q{lib/riak/client/http_backend/object_methods.rb}, %q{lib/riak/client/http_backend/request_headers.rb}, %q{lib/riak/client/http_backend/transport_methods.rb}, %q{lib/riak/client/http_backend.rb}, %q{lib/riak/client/net_http_backend.rb}, %q{lib/riak/client/protobuffs_backend.rb}, %q{lib/riak/client/pump.rb}, %q{lib/riak/client.rb}, %q{lib/riak/core_ext/blank.rb}, %q{lib/riak/core_ext/extract_options.rb}, %q{lib/riak/core_ext/slice.rb}, %q{lib/riak/core_ext/stringify_keys.rb}, %q{lib/riak/core_ext/symbolize_keys.rb}, %q{lib/riak/core_ext/to_param.rb}, %q{lib/riak/core_ext.rb}, %q{lib/riak/failed_request.rb}, %q{lib/riak/i18n.rb}, %q{lib/riak/json.rb}, %q{lib/riak/link.rb}, %q{lib/riak/locale/en.yml}, %q{lib/riak/map_reduce/filter_builder.rb}, %q{lib/riak/map_reduce/phase.rb}, %q{lib/riak/map_reduce.rb}, %q{lib/riak/map_reduce_error.rb}, %q{lib/riak/robject.rb}, %q{lib/riak/search.rb}, %q{lib/riak/test_server.rb}, %q{lib/riak/util/escape.rb}, %q{lib/riak/util/fiber1.8.rb}, %q{lib/riak/util/headers.rb}, %q{lib/riak/util/multipart/stream_parser.rb}, %q{lib/riak/util/multipart.rb}, %q{lib/riak/util/tcp_socket_extensions.rb}, %q{lib/riak/util/translation.rb}, %q{lib/riak/walk_spec.rb}, %q{lib/riak.rb}, %q{Rakefile}, %q{riak-client.gemspec}, %q{spec/fixtures/cat.jpg}, %q{spec/fixtures/multipart-blank.txt}, %q{spec/fixtures/multipart-mapreduce.txt}, %q{spec/fixtures/multipart-with-body.txt}, %q{spec/fixtures/server.cert.crt}, %q{spec/fixtures/server.cert.key}, %q{spec/fixtures/test.pem}, %q{spec/integration/riak/cache_store_spec.rb}, %q{spec/integration/riak/http_backends_spec.rb}, %q{spec/integration/riak/protobuffs_backends_spec.rb}, %q{spec/integration/riak/test_server_spec.rb}, %q{spec/riak/beefcake_protobuffs_backend_spec.rb}, %q{spec/riak/bucket_spec.rb}, %q{spec/riak/client_spec.rb}, %q{spec/riak/core_ext/to_param_spec.rb}, %q{spec/riak/curb_backend_spec.rb}, %q{spec/riak/escape_spec.rb}, %q{spec/riak/excon_backend_spec.rb}, %q{spec/riak/headers_spec.rb}, %q{spec/riak/http_backend/configuration_spec.rb}, %q{spec/riak/http_backend/object_methods_spec.rb}, %q{spec/riak/http_backend/transport_methods_spec.rb}, %q{spec/riak/http_backend_spec.rb}, %q{spec/riak/link_spec.rb}, %q{spec/riak/map_reduce/filter_builder_spec.rb}, %q{spec/riak/map_reduce/phase_spec.rb}, %q{spec/riak/map_reduce_spec.rb}, %q{spec/riak/multipart_spec.rb}, %q{spec/riak/net_http_backend_spec.rb}, %q{spec/riak/robject_spec.rb}, %q{spec/riak/search_spec.rb}, %q{spec/riak/stream_parser_spec.rb}, %q{spec/riak/walk_spec_spec.rb}, %q{spec/spec_helper.rb}, %q{spec/support/drb_mock_server.rb}, %q{spec/support/http_backend_implementation_examples.rb}, %q{spec/support/mock_server.rb}, %q{spec/support/mocks.rb}, %q{spec/support/test_server.yml.example}, %q{spec/support/unified_backend_examples.rb}]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{riak-client is a rich client for Riak, the distributed database by Basho.}
  s.test_files = [%q{spec/integration/riak/cache_store_spec.rb}, %q{spec/integration/riak/http_backends_spec.rb}, %q{spec/integration/riak/protobuffs_backends_spec.rb}, %q{spec/integration/riak/test_server_spec.rb}, %q{spec/riak/beefcake_protobuffs_backend_spec.rb}, %q{spec/riak/bucket_spec.rb}, %q{spec/riak/client_spec.rb}, %q{spec/riak/core_ext/to_param_spec.rb}, %q{spec/riak/curb_backend_spec.rb}, %q{spec/riak/escape_spec.rb}, %q{spec/riak/excon_backend_spec.rb}, %q{spec/riak/headers_spec.rb}, %q{spec/riak/http_backend/configuration_spec.rb}, %q{spec/riak/http_backend/object_methods_spec.rb}, %q{spec/riak/http_backend/transport_methods_spec.rb}, %q{spec/riak/http_backend_spec.rb}, %q{spec/riak/link_spec.rb}, %q{spec/riak/map_reduce/filter_builder_spec.rb}, %q{spec/riak/map_reduce/phase_spec.rb}, %q{spec/riak/map_reduce_spec.rb}, %q{spec/riak/multipart_spec.rb}, %q{spec/riak/net_http_backend_spec.rb}, %q{spec/riak/robject_spec.rb}, %q{spec/riak/search_spec.rb}, %q{spec/riak/stream_parser_spec.rb}, %q{spec/riak/walk_spec_spec.rb}]

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
      s.add_runtime_dependency(%q<beefcake>, ["= 0.3.2"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_dependency(%q<fakeweb>, [">= 1.2"])
      s.add_dependency(%q<rack>, [">= 1.0"])
      s.add_dependency(%q<curb>, [">= 0.6"])
      s.add_dependency(%q<excon>, ["~> 0.5.7"])
      s.add_dependency(%q<i18n>, [">= 0.4.0"])
      s.add_dependency(%q<builder>, ["~> 2.1.2"])
      s.add_dependency(%q<beefcake>, ["= 0.3.2"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.4.0"])
    s.add_dependency(%q<fakeweb>, [">= 1.2"])
    s.add_dependency(%q<rack>, [">= 1.0"])
    s.add_dependency(%q<curb>, [">= 0.6"])
    s.add_dependency(%q<excon>, ["~> 0.5.7"])
    s.add_dependency(%q<i18n>, [">= 0.4.0"])
    s.add_dependency(%q<builder>, ["~> 2.1.2"])
    s.add_dependency(%q<beefcake>, ["= 0.3.2"])
  end
end
