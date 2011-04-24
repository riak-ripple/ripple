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
unless Object.new.respond_to? :to_query and Object.new.respond_to? :to_param
  class Object
    def to_param
      to_s
    end

    def to_query(key)
      require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
      "#{CGI.escape(key.to_s)}=#{CGI.escape(to_param.to_s)}"
    end
  end

  class Array
    def to_param
      map(&:to_param).join('/')
    end

    def to_query(key)
      prefix = "#{key}[]"
      collect { |value| value.to_query(prefix) }.join '&'
    end
  end

  class Hash
    def to_param
      map do |key, value|
        value.to_query(key)
      end.sort * '&'
    end
  end
end
