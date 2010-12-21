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

module Ripple
  module Observer
    extend ActiveSupport::Concern
    include ActiveModel::Observing

    included do
      set_callback(:create, :before)     { notify_observers :before_create }
      set_callback(:create, :after)      { notify_observers :after_create }

      set_callback(:update, :before)     { notify_observers :before_update }
      set_callback(:update, :after)      { notify_observers :after_update }

      set_callback(:save, :before)       { notify_observers :before_save }
      set_callback(:save, :after)        { notify_observers :after_save }

      set_callback(:destroy, :before)    { notify_observers :before_destroy }
      set_callback(:destroy, :after)     { notify_observers :after_destroy }

      set_callback(:validation, :before) { notify_observers :before_validation }
      set_callback(:validation, :after)  { notify_observers :after_validation }
    end

  end
end
