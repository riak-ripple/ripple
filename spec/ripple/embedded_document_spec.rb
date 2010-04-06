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
require File.expand_path("../../spec_helper", __FILE__)

describe Ripple::EmbeddedDocument do
  class Address; include Ripple::EmbeddedDocument; end

  it "should have a model name when included" do
    Address.should respond_to(:model_name)
    Address.model_name.should be_kind_of(ActiveModel::Name)
  end

  it "should be embeddable" do
    Address.should be_embeddable
  end
end
