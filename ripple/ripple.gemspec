# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ripple}
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sean Cribbs"]
  s.date = %q{2010-05-06}
  s.description = %q{ripple is an object-mapper library for Riak, the distributed database by Basho.  It uses ActiveModel to provide an experience that integrates well with Rails 3 applications.}
  s.email = %q{seancribbs@gmail.com}
  s.files = ["lib/ripple/core_ext/casting.rb", "lib/ripple/document/associations/embedded.rb", "lib/ripple/document/associations/instantiators.rb", "lib/ripple/document/associations/linked.rb", "lib/ripple/document/associations/many.rb", "lib/ripple/document/associations/many_embedded_proxy.rb", "lib/ripple/document/associations/one.rb", "lib/ripple/document/associations/one_embedded_proxy.rb", "lib/ripple/document/associations/proxy.rb", "lib/ripple/document/associations.rb", "lib/ripple/document/attribute_methods/dirty.rb", "lib/ripple/document/attribute_methods/query.rb", "lib/ripple/document/attribute_methods/read.rb", "lib/ripple/document/attribute_methods/write.rb", "lib/ripple/document/attribute_methods.rb", "lib/ripple/document/bucket_access.rb", "lib/ripple/document/callbacks.rb", "lib/ripple/document/finders.rb", "lib/ripple/document/persistence.rb", "lib/ripple/document/properties.rb", "lib/ripple/document/timestamps.rb", "lib/ripple/document/validations/associated_validator.rb", "lib/ripple/document/validations.rb", "lib/ripple/document.rb", "lib/ripple/embedded_document/conversion.rb", "lib/ripple/embedded_document/finders.rb", "lib/ripple/embedded_document/persistence.rb", "lib/ripple/embedded_document.rb", "lib/ripple/i18n.rb", "lib/ripple/locale/en.yml", "lib/ripple/property_type_mismatch.rb", "lib/ripple/railtie.rb", "lib/ripple/translation.rb", "lib/ripple.rb", "Rakefile", "spec/fixtures/config.yml", "spec/integration/ripple/associations_spec.rb", "spec/integration/ripple/persistence_spec.rb", "spec/ripple/associations/many_embedded_proxy_spec.rb", "spec/ripple/associations/one_embedded_proxy_spec.rb", "spec/ripple/associations/proxy_spec.rb", "spec/ripple/associations_spec.rb", "spec/ripple/attribute_methods_spec.rb", "spec/ripple/bucket_access_spec.rb", "spec/ripple/callbacks_spec.rb", "spec/ripple/core_ext_spec.rb", "spec/ripple/document_spec.rb", "spec/ripple/embedded_document/conversion_spec.rb", "spec/ripple/embedded_document/finders_spec.rb", "spec/ripple/embedded_document/persistence_spec.rb", "spec/ripple/embedded_document_spec.rb", "spec/ripple/finders_spec.rb", "spec/ripple/persistence_spec.rb", "spec/ripple/properties_spec.rb", "spec/ripple/ripple_spec.rb", "spec/ripple/timestamps_spec.rb", "spec/ripple/validations_spec.rb", "spec/spec_helper.rb", "spec/support/associations/proxies.rb", "spec/support/integration.rb", "spec/support/mocks.rb", "spec/support/models/address.rb", "spec/support/models/box.rb", "spec/support/models/cardboard_box.rb", "spec/support/models/clock.rb", "spec/support/models/customer.rb", "spec/support/models/email.rb", "spec/support/models/family.rb", "spec/support/models/favorite.rb", "spec/support/models/invoice.rb", "spec/support/models/late_invoice.rb", "spec/support/models/note.rb", "spec/support/models/page.rb", "spec/support/models/paid_invoice.rb", "spec/support/models/tree.rb", "spec/support/models/user.rb", "spec/support/models/widget.rb"]
  s.homepage = %q{http://seancribbs.github.com/ripple}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{ripple is an object-mapper library for Riak, the distributed database by Basho.}
  s.test_files = ["spec/integration/ripple/associations_spec.rb", "spec/integration/ripple/persistence_spec.rb", "spec/ripple/associations/many_embedded_proxy_spec.rb", "spec/ripple/associations/one_embedded_proxy_spec.rb", "spec/ripple/associations/proxy_spec.rb", "spec/ripple/associations_spec.rb", "spec/ripple/attribute_methods_spec.rb", "spec/ripple/bucket_access_spec.rb", "spec/ripple/callbacks_spec.rb", "spec/ripple/core_ext_spec.rb", "spec/ripple/document_spec.rb", "spec/ripple/embedded_document/conversion_spec.rb", "spec/ripple/embedded_document/finders_spec.rb", "spec/ripple/embedded_document/persistence_spec.rb", "spec/ripple/embedded_document_spec.rb", "spec/ripple/finders_spec.rb", "spec/ripple/persistence_spec.rb", "spec/ripple/properties_spec.rb", "spec/ripple/ripple_spec.rb", "spec/ripple/timestamps_spec.rb", "spec/ripple/validations_spec.rb", "spec/spec_helper.rb", "spec/support/associations/proxies.rb", "spec/support/integration.rb", "spec/support/mocks.rb", "spec/support/models/address.rb", "spec/support/models/box.rb", "spec/support/models/cardboard_box.rb", "spec/support/models/clock.rb", "spec/support/models/customer.rb", "spec/support/models/email.rb", "spec/support/models/family.rb", "spec/support/models/favorite.rb", "spec/support/models/invoice.rb", "spec/support/models/late_invoice.rb", "spec/support/models/note.rb", "spec/support/models/page.rb", "spec/support/models/paid_invoice.rb", "spec/support/models/tree.rb", "spec/support/models/user.rb", "spec/support/models/widget.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.0.0.beta.6"])
      s.add_runtime_dependency(%q<riak-client>, ["= 0.7.0"])
      s.add_runtime_dependency(%q<activesupport>, ["= 3.0.0.beta3"])
      s.add_runtime_dependency(%q<activemodel>, ["= 3.0.0.beta3"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.0.0.beta.6"])
      s.add_dependency(%q<riak-client>, ["= 0.7.0"])
      s.add_dependency(%q<activesupport>, ["= 3.0.0.beta3"])
      s.add_dependency(%q<activemodel>, ["= 3.0.0.beta3"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.0.0.beta.6"])
    s.add_dependency(%q<riak-client>, ["= 0.7.0"])
    s.add_dependency(%q<activesupport>, ["= 3.0.0.beta3"])
    s.add_dependency(%q<activemodel>, ["= 3.0.0.beta3"])
  end
end
