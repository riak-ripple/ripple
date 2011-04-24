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
unless {}.respond_to? :slice
  class Hash
    def slice(*keys)
      allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      hash = {}
      allowed.each { |k| hash[k] = self[k] if has_key?(k) }
      hash
    end

    def slice!(*keys)
      keys = keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
      omit = slice(*self.keys - keys)
      hash = slice(*keys)
      replace(hash)
      omit
    end
  end
end
