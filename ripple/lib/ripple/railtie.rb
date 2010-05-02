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
require 'ripple'
require 'rails'

# require in gemfile using
# <tt>gem "ripple", :require_as => ["ripple", "ripple/railtie"]</tt>
module Ripple
  class Railtie < Rails::Railtie
    railtie_name :ripple
    
    initializer "ripple.configure_rails_initialization" do
      Ripple.load_configuration
    end
  end
  
  def self.load_configuration
    config_file = Rails.root.join('config', 'database.yml')
    self.config = YAML.load_file(File.expand_path config_file).with_indifferent_access[:ripple][Rails.env]
  end
end