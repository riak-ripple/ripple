# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ripple}
  s.version = "0.9.0.beta2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sean Cribbs"]
  s.date = %q{2011-03-28}
  s.description = %q{ripple is an object-mapper library for Riak, the distributed database by Basho.  It uses ActiveModel to provide an experience that integrates well with Rails 3 applications.}
  s.email = %q{sean@basho.com}
  s.files = ["Gemfile", "lib/rails/generators/ripple/configuration/configuration_generator.rb", "lib/rails/generators/ripple/configuration/templates/ripple.yml", "lib/rails/generators/ripple/js/js_generator.rb", "lib/rails/generators/ripple/js/templates/js/contrib.js", "lib/rails/generators/ripple/js/templates/js/iso8601.js", "lib/rails/generators/ripple/js/templates/js/ripple.js", "lib/rails/generators/ripple/model/model_generator.rb", "lib/rails/generators/ripple/model/templates/model.rb", "lib/rails/generators/ripple/observer/observer_generator.rb", "lib/rails/generators/ripple/observer/templates/observer.rb", "lib/rails/generators/ripple/test/templates/test_server.rb", "lib/rails/generators/ripple/test/test_generator.rb", "lib/rails/generators/ripple_generator.rb", "lib/ripple/associations/embedded.rb", "lib/ripple/associations/instantiators.rb", "lib/ripple/associations/linked.rb", "lib/ripple/associations/many.rb", "lib/ripple/associations/many_embedded_proxy.rb", "lib/ripple/associations/many_linked_proxy.rb", "lib/ripple/associations/one.rb", "lib/ripple/associations/one_embedded_proxy.rb", "lib/ripple/associations/one_linked_proxy.rb", "lib/ripple/associations/proxy.rb", "lib/ripple/associations.rb", "lib/ripple/attribute_methods/dirty.rb", "lib/ripple/attribute_methods/query.rb", "lib/ripple/attribute_methods/read.rb", "lib/ripple/attribute_methods/write.rb", "lib/ripple/attribute_methods.rb", "lib/ripple/callbacks.rb", "lib/ripple/conversion.rb", "lib/ripple/core_ext/casting.rb", "lib/ripple/core_ext.rb", "lib/ripple/document/bucket_access.rb", "lib/ripple/document/finders.rb", "lib/ripple/document/key.rb", "lib/ripple/document/persistence.rb", "lib/ripple/document.rb", "lib/ripple/embedded_document/finders.rb", "lib/ripple/embedded_document/persistence.rb", "lib/ripple/embedded_document.rb", "lib/ripple/i18n.rb", "lib/ripple/inspection.rb", "lib/ripple/locale/en.yml", "lib/ripple/nested_attributes.rb", "lib/ripple/observable.rb", "lib/ripple/properties.rb", "lib/ripple/property_type_mismatch.rb", "lib/ripple/railtie.rb", "lib/ripple/timestamps.rb", "lib/ripple/translation.rb", "lib/ripple/validations/associated_validator.rb", "lib/ripple/validations.rb", "lib/ripple.rb", "Rakefile", "ripple.gemspec", "spec/fixtures/config.yml", "spec/integration/ripple/associations_spec.rb", "spec/integration/ripple/nested_attributes_spec.rb", "spec/integration/ripple/persistence_spec.rb", "spec/ripple/associations/many_embedded_proxy_spec.rb", "spec/ripple/associations/many_linked_proxy_spec.rb", "spec/ripple/associations/one_embedded_proxy_spec.rb", "spec/ripple/associations/one_linked_proxy_spec.rb", "spec/ripple/associations/proxy_spec.rb", "spec/ripple/associations_spec.rb", "spec/ripple/attribute_methods_spec.rb", "spec/ripple/bucket_access_spec.rb", "spec/ripple/callbacks_spec.rb", "spec/ripple/conversion_spec.rb", "spec/ripple/core_ext_spec.rb", "spec/ripple/document_spec.rb", "spec/ripple/embedded_document/finders_spec.rb", "spec/ripple/embedded_document/persistence_spec.rb", "spec/ripple/embedded_document_spec.rb", "spec/ripple/finders_spec.rb", "spec/ripple/inspection_spec.rb", "spec/ripple/key_spec.rb", "spec/ripple/observable_spec.rb", "spec/ripple/persistence_spec.rb", "spec/ripple/properties_spec.rb", "spec/ripple/ripple_spec.rb", "spec/ripple/timestamps_spec.rb", "spec/ripple/validations_spec.rb", "spec/spec_helper.rb", "spec/support/associations/proxies.rb", "spec/support/mocks.rb", "spec/support/models/address.rb", "spec/support/models/box.rb", "spec/support/models/car.rb", "spec/support/models/cardboard_box.rb", "spec/support/models/clock.rb", "spec/support/models/customer.rb", "spec/support/models/driver.rb", "spec/support/models/email.rb", "spec/support/models/engine.rb", "spec/support/models/family.rb", "spec/support/models/favorite.rb", "spec/support/models/invoice.rb", "spec/support/models/late_invoice.rb", "spec/support/models/note.rb", "spec/support/models/page.rb", "spec/support/models/paid_invoice.rb", "spec/support/models/passenger.rb", "spec/support/models/seat.rb", "spec/support/models/tasks.rb", "spec/support/models/tree.rb", "spec/support/models/user.rb", "spec/support/models/wheel.rb", "spec/support/models/widget.rb", "spec/support/test_server.rb", "spec/support/test_server.yml.example"]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.1}
  s.summary = %q{ripple is an object-mapper library for Riak, the distributed database by Basho.}
  s.test_files = ["spec/integration/ripple/associations_spec.rb", "spec/integration/ripple/nested_attributes_spec.rb", "spec/integration/ripple/persistence_spec.rb", "spec/ripple/associations/many_embedded_proxy_spec.rb", "spec/ripple/associations/many_linked_proxy_spec.rb", "spec/ripple/associations/one_embedded_proxy_spec.rb", "spec/ripple/associations/one_linked_proxy_spec.rb", "spec/ripple/associations/proxy_spec.rb", "spec/ripple/associations_spec.rb", "spec/ripple/attribute_methods_spec.rb", "spec/ripple/bucket_access_spec.rb", "spec/ripple/callbacks_spec.rb", "spec/ripple/conversion_spec.rb", "spec/ripple/core_ext_spec.rb", "spec/ripple/document_spec.rb", "spec/ripple/embedded_document/finders_spec.rb", "spec/ripple/embedded_document/persistence_spec.rb", "spec/ripple/embedded_document_spec.rb", "spec/ripple/finders_spec.rb", "spec/ripple/inspection_spec.rb", "spec/ripple/key_spec.rb", "spec/ripple/observable_spec.rb", "spec/ripple/persistence_spec.rb", "spec/ripple/properties_spec.rb", "spec/ripple/ripple_spec.rb", "spec/ripple/timestamps_spec.rb", "spec/ripple/validations_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_runtime_dependency(%q<riak-client>, ["~> 0.9.0.beta2"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<activemodel>, ["~> 3.0.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_dependency(%q<riak-client>, ["~> 0.9.0.beta2"])
      s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_dependency(%q<activemodel>, ["~> 3.0.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.4.0"])
    s.add_dependency(%q<riak-client>, ["~> 0.9.0.beta2"])
    s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
    s.add_dependency(%q<activemodel>, ["~> 3.0.0"])
  end
end
