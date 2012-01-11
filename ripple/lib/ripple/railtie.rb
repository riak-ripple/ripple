require 'rails/railtie'

module Ripple
  # Railtie for automatic initialization of the Ripple framework
  # during Rails initialization.
  class Railtie < Rails::Railtie
    rake_tasks do
      load "ripple/railties/ripple.rake"
    end

    initializer "ripple.configure_rails_initialization" do
      if File.exist?(Rails.root + "config/ripple.yml")
        Ripple.load_configuration Rails.root.join('config', 'ripple.yml'), [Rails.env]
      end
    end

    initializer "ripple.configure_test_server_root", :after => "ripple.configure_rails_initialization" do
      unless Rails.env.development? || Rails.env.production?
        # Make sure the TestServer lives in the default location, if
        # not set in the config file.
        Ripple.config[:root] ||= (Rails.root + 'tmp/riak_test_server').to_s
        Ripple.config[:js_source_dir] ||= (Rails.root + "app/mapreduce").to_s
      end
    end
  end
end
