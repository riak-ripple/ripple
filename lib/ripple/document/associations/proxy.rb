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
  module Document
    module Associations
      class Proxy
        alias :proxy_respond_to? :respond_to?
        alias :proxy_extend :extend

        instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }

        attr_reader :owner, :reflection, :target

        alias :proxy_owner :owner
        alias :proxy_target :target
        alias :proxy_reflection :reflection

        delegate :klass, :to => :proxy_reflection
        delegate :options, :to => :proxy_reflection
        delegate :collection, :to => :klass

        def initialize(owner, reflection)
          @owner, @reflection, @loaded = owner, reflection, false
          Array(reflection.options[:extend]).each { |ext| proxy_extend(ext) } if reflection.options[:extend]
          reset
        end

        def inspect
          load_target
          target.inspect
        end

        def loaded?
          @loaded
        end

        def loaded
          @loaded = true
        end

        def nil?
          load_target
          target.nil?
        end

        def blank?
          load_target
          target.blank?
        end

        def present?
          load_target
          target.present?
        end

        def reload
          reset
          load_target
          self unless target.nil?
        end

        def replace(v)
          raise NotImplementedError
        end

        def reset
          @loaded = false
          @target = nil
        end

        def respond_to?(*args)
          proxy_respond_to?(*args) || (load_target && target.respond_to?(*args))
        end

        def send(method, *args, &block)
          if proxy_respond_to?(method)
            super
          else
            load_target
            target.send(method, *args, &block)
          end
        end

        def ===(other)
          load_target
          other === target
        end

        protected
        def method_missing(method, *args, &block)
          if load_target
            if block_given?
              target.send(method, *args)  { |*block_args| block.call(*block_args) }
            else
              target.send(method, *args)
            end
          end
        end

        def load_target
          @target = find_target unless loaded?
          loaded
          @target
        end

        def find_target
          raise NotImplementedError
        end
      end
    end
  end
end
