# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

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
        template 'model.rb', "app/models/#{file_path}.rb"
      end

      hook_for :test_framework
    end
  end
end
