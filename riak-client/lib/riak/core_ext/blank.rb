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
require 'set'

unless Object.new.respond_to? :blank?
  class Object
    def blank?
      false
    end
  end

  class NilClass
    def blank?
      true
    end
  end

  class FalseClass
    def blank?
      true
    end
  end

  class TrueClass
    def blank?
      false
    end
  end

  class Set
    alias :blank? :empty?
  end

  class String
    def blank?
      self !~ /[^\s]/
    end
  end

  class Array
    alias :blank? :empty?
  end

  class Hash
    alias :blank? :empty?
  end
end

unless Object.new.respond_to? :present?
  class Object
    def present?
      !blank?
    end
  end
end
