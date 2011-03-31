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
require File.expand_path("../../../spec_helper", __FILE__)

describe "Ripple Associations" do
  require 'support/test_server'

  before :all do
    Object.module_eval do
      class User
        include Ripple::Document
        one  :profile
        many :addresses
        property :email, String, :presence => true
        many :friends, :class_name => "User"
        one :emergency_contact, :class_name => "User"
      end
      class Profile
        include Ripple::EmbeddedDocument
        property :name, String, :presence => true
        embedded_in :user
      end
      class Address
        include Ripple::EmbeddedDocument
        property :street, String, :presence => true
        property :kind,   String, :presence => true
        embedded_in :user
      end
    end
  end

  before :each do
    @user     = User.new(:email => 'riak@ripple.com')
    @profile  = Profile.new(:name => 'Ripple')
    @billing  = Address.new(:street => '123 Somewhere Dr', :kind => 'billing')
    @shipping = Address.new(:street => '321 Anywhere Pl', :kind => 'shipping')
    @friend1 = User.create(:email => "friend@ripple.com")
    @friend2 = User.create(:email => "friend2@ripple.com")
  end

  it "should save one embedded associations" do
    @user.profile = @profile
    @user.save
    @found = User.find(@user.key)
    @found.profile.name.should == 'Ripple'
    @found.profile.should be_a(Profile)
    @found.profile.user.should == @found
  end

  it "should not raise an error when a one linked associated record has been deleted" do
    @user.emergency_contact = @friend1
    @user.save

    @friend1.destroy
    @found = User.find(@user.key)
    @found.emergency_contact.should be_nil
  end

  it "should save many embedded associations" do
    @user.addresses << @billing << @shipping
    @user.save
    @found = User.find(@user.key)
    @found.addresses.count.should == 2
    @bill = @found.addresses.detect {|a| a.kind == 'billing'}
    @ship = @found.addresses.detect {|a| a.kind == 'shipping'}
    @bill.street.should == '123 Somewhere Dr'
    @ship.street.should == '321 Anywhere Pl'
    @bill.user.should == @found
    @ship.user.should == @found
    @bill.should be_a(Address)
    @ship.should be_a(Address)
  end

  it "should save a many linked association" do
    @user.friends << @friend1 << @friend2
    @user.save
    @user.should_not be_new_record
    @found = User.find(@user.key)
    @found.friends.map(&:key).should include(@friend1.key)
    @found.friends.map(&:key).should include(@friend2.key)
  end

  it "should save a one linked association" do
    @user.emergency_contact = @friend1
    @user.save
    @user.should_not be_new_record
    @found = User.find(@user.key)
    @found.emergency_contact.key.should == @friend1.key
  end

  after :each do
    User.destroy_all
  end

  after :all do
    Object.send(:remove_const, :User)
    Object.send(:remove_const, :Profile)
    Object.send(:remove_const, :Address)
  end

end
