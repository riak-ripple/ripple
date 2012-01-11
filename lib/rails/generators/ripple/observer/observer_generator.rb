require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class ObserverGenerator < NamedBase
      desc 'Creates an observer for Ripple documents'
      check_class_collision :suffix => "Observer"

      def create_observer_file
        template 'observer.rb.erb', File.join("app/models", class_path, "#{file_name}_observer.rb")
      end

      hook_for :test_framework
    end
  end
end
