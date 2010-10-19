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
require 'riak'

module Riak
  module Util
    # Methods for doing i18n string lookup
    module Translation
      # The scope of i18n messages
      def i18n_scope
        :riak
      end

      # Provides the translation for a given internationalized message
      def t(message, options={})
        I18n.t("#{i18n_scope}.#{message}", options)
      end
    end
  end
end

