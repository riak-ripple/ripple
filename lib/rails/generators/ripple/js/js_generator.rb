require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class JsGenerator < Base
      desc 'Generates Javascript built-ins for use in your queries.'

      def create_js_files
        directory 'js', 'app/mapreduce'
      end
    end
  end
end
