# Copyright 2010-2011 Sean Cribbs and Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rails/generators/ripple_generator'

module Ripple
  module Generators
    class ObserverGenerator < NamedBase
      desc 'Creates an observer for Ripple documents'
      check_class_collision :suffix => "Observer"

      def create_observer_file
        template 'observer.rb', File.join("app/models", class_path, "#{file_name}_observer.rb")
      end

      hook_for :test_framework
    end
  end
end
