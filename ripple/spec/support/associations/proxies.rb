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


class FakeNilProxy < Ripple::Associations::Proxy
  def find_target; nil end
end

class FakeBlankProxy < Ripple::Associations::Proxy
  def find_target; '' end
end

class FakeNumberProxy < Ripple::Associations::Proxy
  def find_target; 17 end
end

class FakeProxy < Ripple::Associations::Proxy
  def find_target; [1, 2] end
end
