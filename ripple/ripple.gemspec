# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ripple}
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Sean Cribbs}]
  s.date = %q{2011-06-14}
  s.description = %q{ripple is an object-mapper library for Riak, the distributed database by Basho.  It uses ActiveModel to provide an experience that integrates well with Rails 3 applications.}
  s.email = %q{sean@basho.com}
  s.files = [%q{Gemfile}, %q{lib/rails/generators/ripple/configuration/configuration_generator.rb}, %q{lib/rails/generators/ripple/configuration/templates/ripple.yml}, %q{lib/rails/generators/ripple/js/js_generator.rb}, %q{lib/rails/generators/ripple/js/templates/js/contrib.js}, %q{lib/rails/generators/ripple/js/templates/js/iso8601.js}, %q{lib/rails/generators/ripple/js/templates/js/ripple.js}, %q{lib/rails/generators/ripple/model/model_generator.rb}, %q{lib/rails/generators/ripple/model/templates/model.rb}, %q{lib/rails/generators/ripple/observer/observer_generator.rb}, %q{lib/rails/generators/ripple/observer/templates/observer.rb}, %q{lib/rails/generators/ripple/test/templates/test_server.rb}, %q{lib/rails/generators/ripple/test/test_generator.rb}, %q{lib/rails/generators/ripple_generator.rb}, %q{lib/ripple/associations/embedded.rb}, %q{lib/ripple/associations/instantiators.rb}, %q{lib/ripple/associations/linked.rb}, %q{lib/ripple/associations/many.rb}, %q{lib/ripple/associations/many_embedded_proxy.rb}, %q{lib/ripple/associations/many_linked_proxy.rb}, %q{lib/ripple/associations/one.rb}, %q{lib/ripple/associations/one_embedded_proxy.rb}, %q{lib/ripple/associations/one_linked_proxy.rb}, %q{lib/ripple/associations/proxy.rb}, %q{lib/ripple/associations.rb}, %q{lib/ripple/attribute_methods/dirty.rb}, %q{lib/ripple/attribute_methods/query.rb}, %q{lib/ripple/attribute_methods/read.rb}, %q{lib/ripple/attribute_methods/write.rb}, %q{lib/ripple/attribute_methods.rb}, %q{lib/ripple/callbacks.rb}, %q{lib/ripple/conversion.rb}, %q{lib/ripple/core_ext/casting.rb}, %q{lib/ripple/core_ext.rb}, %q{lib/ripple/document/bucket_access.rb}, %q{lib/ripple/document/finders.rb}, %q{lib/ripple/document/key.rb}, %q{lib/ripple/document/persistence.rb}, %q{lib/ripple/document.rb}, %q{lib/ripple/embedded_document/finders.rb}, %q{lib/ripple/embedded_document/persistence.rb}, %q{lib/ripple/embedded_document.rb}, %q{lib/ripple/i18n.rb}, %q{lib/ripple/inspection.rb}, %q{lib/ripple/locale/en.yml}, %q{lib/ripple/nested_attributes.rb}, %q{lib/ripple/observable.rb}, %q{lib/ripple/properties.rb}, %q{lib/ripple/property_type_mismatch.rb}, %q{lib/ripple/railtie.rb}, %q{lib/ripple/serialization.rb}, %q{lib/ripple/timestamps.rb}, %q{lib/ripple/translation.rb}, %q{lib/ripple/validations/associated_validator.rb}, %q{lib/ripple/validations.rb}, %q{lib/ripple.rb}, %q{Rakefile}, %q{ripple.gemspec}, %q{spec/fixtures/config.yml}, %q{spec/integration/ripple/associations_spec.rb}, %q{spec/integration/ripple/nested_attributes_spec.rb}, %q{spec/integration/ripple/persistence_spec.rb}, %q{spec/ripple/associations/many_embedded_proxy_spec.rb}, %q{spec/ripple/associations/many_linked_proxy_spec.rb}, %q{spec/ripple/associations/one_embedded_proxy_spec.rb}, %q{spec/ripple/associations/one_linked_proxy_spec.rb}, %q{spec/ripple/associations/proxy_spec.rb}, %q{spec/ripple/associations_spec.rb}, %q{spec/ripple/attribute_methods/dirty_spec.rb}, %q{spec/ripple/attribute_methods_spec.rb}, %q{spec/ripple/bucket_access_spec.rb}, %q{spec/ripple/callbacks_spec.rb}, %q{spec/ripple/conversion_spec.rb}, %q{spec/ripple/core_ext_spec.rb}, %q{spec/ripple/document_spec.rb}, %q{spec/ripple/embedded_document/finders_spec.rb}, %q{spec/ripple/embedded_document/persistence_spec.rb}, %q{spec/ripple/embedded_document_spec.rb}, %q{spec/ripple/finders_spec.rb}, %q{spec/ripple/inspection_spec.rb}, %q{spec/ripple/key_spec.rb}, %q{spec/ripple/observable_spec.rb}, %q{spec/ripple/persistence_spec.rb}, %q{spec/ripple/properties_spec.rb}, %q{spec/ripple/ripple_spec.rb}, %q{spec/ripple/serialization_spec.rb}, %q{spec/ripple/timestamps_spec.rb}, %q{spec/ripple/validations/associated_validator_spec.rb}, %q{spec/ripple/validations_spec.rb}, %q{spec/spec_helper.rb}, %q{spec/support/associations/proxies.rb}, %q{spec/support/associations.rb}, %q{spec/support/mocks.rb}, %q{spec/support/models/address.rb}, %q{spec/support/models/box.rb}, %q{spec/support/models/car.rb}, %q{spec/support/models/cardboard_box.rb}, %q{spec/support/models/clock.rb}, %q{spec/support/models/clock_observer.rb}, %q{spec/support/models/company.rb}, %q{spec/support/models/customer.rb}, %q{spec/support/models/driver.rb}, %q{spec/support/models/email.rb}, %q{spec/support/models/engine.rb}, %q{spec/support/models/family.rb}, %q{spec/support/models/favorite.rb}, %q{spec/support/models/invoice.rb}, %q{spec/support/models/late_invoice.rb}, %q{spec/support/models/note.rb}, %q{spec/support/models/page.rb}, %q{spec/support/models/paid_invoice.rb}, %q{spec/support/models/passenger.rb}, %q{spec/support/models/seat.rb}, %q{spec/support/models/tasks.rb}, %q{spec/support/models/tree.rb}, %q{spec/support/models/user.rb}, %q{spec/support/models/wheel.rb}, %q{spec/support/models/widget.rb}, %q{spec/support/models.rb}, %q{spec/support/test_server.rb}, %q{spec/support/test_server.yml.example}]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{ripple is an object-mapper library for Riak, the distributed database by Basho.}
  s.test_files = [%q{spec/integration/ripple/associations_spec.rb}, %q{spec/integration/ripple/nested_attributes_spec.rb}, %q{spec/integration/ripple/persistence_spec.rb}, %q{spec/ripple/associations/many_embedded_proxy_spec.rb}, %q{spec/ripple/associations/many_linked_proxy_spec.rb}, %q{spec/ripple/associations/one_embedded_proxy_spec.rb}, %q{spec/ripple/associations/one_linked_proxy_spec.rb}, %q{spec/ripple/associations/proxy_spec.rb}, %q{spec/ripple/associations_spec.rb}, %q{spec/ripple/attribute_methods/dirty_spec.rb}, %q{spec/ripple/attribute_methods_spec.rb}, %q{spec/ripple/bucket_access_spec.rb}, %q{spec/ripple/callbacks_spec.rb}, %q{spec/ripple/conversion_spec.rb}, %q{spec/ripple/core_ext_spec.rb}, %q{spec/ripple/document_spec.rb}, %q{spec/ripple/embedded_document/finders_spec.rb}, %q{spec/ripple/embedded_document/persistence_spec.rb}, %q{spec/ripple/embedded_document_spec.rb}, %q{spec/ripple/finders_spec.rb}, %q{spec/ripple/inspection_spec.rb}, %q{spec/ripple/key_spec.rb}, %q{spec/ripple/observable_spec.rb}, %q{spec/ripple/persistence_spec.rb}, %q{spec/ripple/properties_spec.rb}, %q{spec/ripple/ripple_spec.rb}, %q{spec/ripple/serialization_spec.rb}, %q{spec/ripple/timestamps_spec.rb}, %q{spec/ripple/validations/associated_validator_spec.rb}, %q{spec/ripple/validations_spec.rb}]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_runtime_dependency(%q<riak-client>, ["~> 0.9.5"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<activemodel>, ["~> 3.0.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_dependency(%q<riak-client>, ["~> 0.9.5"])
      s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_dependency(%q<activemodel>, ["~> 3.0.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.4.0"])
    s.add_dependency(%q<riak-client>, ["~> 0.9.5"])
    s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
    s.add_dependency(%q<activemodel>, ["~> 3.0.0"])
  end
end
