require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class ModelGenerator < NamedBase
      desc 'Creates a ripple model'
      argument :attributes, :type => :array, :default => [], :banner => 'field:type field:type'
      class_option :parent, :type => :string, :desc => "The parent class for the generated model"
      class_option :embedded, :type => :boolean, :desc => "Make an embedded document model.", :default => false
      class_option :embedded_in, :type => :string, :desc => "Specify the enclosing model for the embedded document. Implies --embedded."
      check_class_collision

      def create_model_file
        template 'model.rb.erb', "app/models/#{file_path}.rb"
      end

      hook_for :test_framework
    end
  end
end
