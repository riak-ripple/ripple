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
require File.expand_path("../../spec_helper", __FILE__)

describe Ripple::EmbeddedDocument do
  require 'support/models/address'
  require 'support/models/user'

  it "should have a model name when included" do
    Address.should respond_to(:model_name)
    Address.model_name.should be_kind_of(ActiveModel::Name)
  end

  it "should be embeddable" do
    Address.should be_embeddable
  end

  describe "#==" do
    let(:user_1) { User.create! }
    let(:user_2) { User.create! }
    let(:street_1) { '123 Somewhere St' }
    let(:street_2) { '123 Somewhere Ave' }
    let(:address_1) { Address.new(:street => street_1) }
    let(:address_2) { Address.new(:street => street_1) }

    before(:each) do
      address_1._parent_document = user_1
      address_2._parent_document = user_1
    end

    it "returns true when the documents have the same classes, parents and attributes" do
      (address_1 == address_2).should be_true
      (address_2 == address_1).should be_true
    end

    it "returns true when the documents match and only one of them includes the _type attribute" do
      attrs = address_1.attributes
      address_1.stub(:attributes => attrs.merge('_type' => 'Address'))

      (address_1 == address_2).should be_true
      (address_2 == address_1).should be_true
    end

    it "returns false when the parents are different (even if the attributes and classes are the same)" do
      address_2._parent_document = user_2
      (address_1 == address_2).should be_false
      (address_2 == address_1).should be_false
    end

    it "returns false when the attributes are different (even if the parents and classes are the same)" do
      address_2.street = street_2
      (address_1 == address_2).should be_false
      (address_2 == address_1).should be_false
    end

    it "returns false then the classes are different (even if the parents and attributes are the same)" do
      special_address = SpecialAddress.new(address_1.attributes)
      special_address._parent_document = address_1._parent_document
      (address_1 == special_address).should be_false
      (special_address == address_1).should be_false
    end
  end
end
