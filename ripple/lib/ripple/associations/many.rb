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
  module Associations
    module Many
      include Instantiators

      def to_ary
        load_target
        Array === target ? target.to_ary : Array(target)
      end

      def count
        load_target
        target.size
      end

      def reset
        super
        @target = []
      end

      def <<(value)
        raise NotImplementedError
      end

      alias_method :push, :<<
      alias_method :concat, :<<

      protected
      def instantiate_target(instantiator, attrs={})
        doc = klass.send(instantiator, attrs)
        self << doc
        doc
      end
    end
  end
end
