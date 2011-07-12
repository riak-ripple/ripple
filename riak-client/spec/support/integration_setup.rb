# auto-tag all integration specs with :integration => true
module IntegrationSpecs
  def self.included(klass)
    klass.metadata[:integration] = true
  end
end

RSpec.configure do |config|
  config.include IntegrationSpecs, :example_group => { :file_path => %r{spec/integration} }
end
