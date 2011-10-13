require 'spec_helper'

describe Ripple::EmbeddedDocument do
  # require 'support/models/address'
  # require 'support/models/user'

  it "should have a model name when included" do
    Address.should respond_to(:model_name)
    Address.model_name.should be_kind_of(ActiveModel::Name)
  end

  it "should be embeddable" do
    Address.should be_embeddable
  end

  describe "equality" do
    let(:user_1) { User.new {|u| u.key = "u1"} }
    let(:user_2) { User.new {|u| u.key = "u2"} }
    let(:street_1) { '123 Somewhere St' }
    let(:street_2) { '123 Somewhere Ave' }
    let(:address_1) { Address.new(:street => street_1) }
    let(:address_2) { Address.new(:street => street_1) }

    before(:each) do
      address_1._parent_document = user_1
      address_2._parent_document = user_1
    end

    def should_be_equal
      (address_1 == address_2).should be_true
      address_1.eql?(address_2).should be_true

      (address_2 == address_1).should be_true
      address_2.eql?(address_1).should be_true

      address_1.hash.should == address_2.hash
    end

    def should_not_be_equal(other_address = address_2)
      (address_1 == other_address).should be_false
      address_1.eql?(other_address).should be_false

      (other_address == address_1).should be_false
      address_1.eql?(other_address).should be_false

      address_1.hash.should_not == other_address.hash
    end

    specify "two document are equal when they have the same classes, parents and attributes" do
      should_be_equal
    end

    specify "two documents are not equal when the parents are different (even if the attributes and classes are the same)" do
      address_2._parent_document = user_2
      should_not_be_equal
    end

    specify "two documents are not equal when the attributes are different (even if the parents and classes are the same)" do
      address_2.street = street_2
      should_not_be_equal
    end

    specify "two documents are not equal when the classes are different (even if the parents and attributes are the same)" do
      special_address = SpecialAddress.new(address_1.attributes)
      special_address._parent_document = address_1._parent_document

      should_not_be_equal(special_address)
    end

    specify "two documents are not equal when their embedded documents are not equal (even if they are identical otherwise)" do
      address_1.notes << Note.new(:text => 'Bob lives here')
      address_2.notes << Note.new(:text => 'Jill lives here')

      should_not_be_equal
    end

    specify "two documents can be equal when their embedded doc objects are different instances but are equal" do
      address_1.notes << Note.new(:text => 'Bob lives here')
      address_2.notes << Note.new(:text => 'Bob lives here')

      should_be_equal
    end
  end
end
