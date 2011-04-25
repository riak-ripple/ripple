
require 'action_mailer' # Bah, fails on MailerExampleGroup
require 'support/rspec-rails-neuter'
require 'rspec/rails/example/rails_example_group'
require 'rspec/rails/example/request_example_group'

class RoutedRackApp
  attr_reader :routes

  def initialize(routes, &blk)
    @routes = routes
    @stack = ActionDispatch::MiddlewareStack.new(&blk).build(@routes)
  end

  def call(env)
    @stack.call(env)
  end
end

module Ripple
  module SessionStoreTest
    class TestController < ActionController::Base
      def no_session_access
        head :ok
      end

      def set_session_value
        session[:foo] = "bar"
        head :ok
      end

      def set_serialized_session_value
        session[:foo] = SessionAutoloadTest::Foo.new
        head :ok
      end

      def get_session_value
        render :text => "foo: #{session[:foo].inspect}"
      end

      def get_session_id
        render :text => "#{request.session_options[:id]}"
      end

      def call_reset_session
        session[:bar]
        reset_session
        session[:bar] = "baz"
        head :ok
      end

      def rescue_action(e) raise end
    end

    def build_app(routes = nil)
      RoutedRackApp.new(routes || ActionDispatch::Routing::RouteSet.new) do |middleware|
        middleware.use "ActionDispatch::ShowExceptions"
        middleware.use "ActionDispatch::Callbacks"
        middleware.use "ActionDispatch::ParamsParser"
        middleware.use "ActionDispatch::Cookies"
        middleware.use "ActionDispatch::Flash"
        middleware.use "ActionDispatch::Head"
        yield(middleware) if block_given?
      end
    end

    def app
      @app || super
    end

    def with_autoload_path(path)
      path = File.join(File.dirname(__FILE__),"..","fixtures", path)
      if ActiveSupport::Dependencies.autoload_paths.include?(path)
        yield
      else
        begin
          ActiveSupport::Dependencies.autoload_paths << path
          yield
        ensure
          ActiveSupport::Dependencies.autoload_paths.reject! {|p| p == path}
          ActiveSupport::Dependencies.clear
        end
      end
    end
  end
end
