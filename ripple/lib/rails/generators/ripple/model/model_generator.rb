require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class ModelGenerator < Base
      desc 'Creates a ripple model'
      argument :attributes, :type => :array, :default => [], :banner => 'field:type field:type'
      class_option :parent, :type => :string, :desc => "The parent class for the generated model"

      check_class_collision

      def create_model_file
        template 'model.rb', "app/models/#{class_path}/#{file_name}.rb"
      end

      hook_for :test_framework
    end
  end
end
