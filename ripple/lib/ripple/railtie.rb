require 'rails/railtie'

module Ripple
  # Railtie for automatic initialization of the Ripple framework
  # during Rails initialization.
  class Railtie < Rails::Railtie
    initializer "ripple.configure_rails_initialization" do
      if File.exist?(Rails.root + "config/ripple.yml")
        Ripple.load_configuration Rails.root.join('config', 'ripple.yml'), [Rails.env]
      end
    end
  end
end
