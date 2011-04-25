require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'active_support/core_ext/array'

describe Ripple::NestedAttributes do
  require 'support/models/car'
  require 'support/models/driver'
  require 'support/models/passenger'
  require 'support/models/engine'
  require 'support/models/seat'
  require 'support/models/wheel'
  require 'support/test_server'

  context "one :driver (link)" do
    subject { Car.new }

    it { should respond_to(:driver_attributes=) }

    it "should not have a driver" do
      subject.driver.should be_nil
    end

    describe "creation" do
      subject { Car.new(:make => 'VW', :model => 'Rabbit', :driver_attributes => { :name => 'Speed Racer' }) }

      it "should have a driver of class Driver" do
        subject.driver.should be_a(Driver)
      end

      it "should have a driver with name 'Speed Racer'" do
        subject.driver.name.should == 'Speed Racer'
      end

      it "should save the child when saving the parent" do
        subject.driver.should_receive(:save)
        subject.save
      end
    end

    describe "update" do
      let(:driver) { Driver.create(:name => 'Slow Racer') }

      before do
        subject.driver = driver
        subject.save
      end

      it "should have a driver" do
        subject.driver.should == driver
      end

      it "should update attributes" do
        subject.driver_attributes = { :name => 'Speed Racer' }
        subject.driver.name.should == 'Speed Racer'
      end

      it "should not save the child if attributes haven't been updated" do
        subject.driver.should_not_receive(:save)
        subject.save
      end

      it "should save the child when saving the parent" do
        subject.driver_attributes = { :name => 'Speed Racer' }
        subject.driver.should_receive(:save)
        subject.save
      end
    end
  end

  context "many :passengers (link)" do
    subject { Car.new }

    it { should respond_to(:passengers_attributes=) }

    it "should not have passengers" do
      subject.passengers.should == []
    end

    describe "creation" do
      subject { Car.new(:make => 'VW',
                        :model => 'Rabbit',
                        :passengers_attributes => [ { :name => 'Joe' },
                                                    { :name => 'Sue' },
                                                    { :name => 'Pat' } ] ) }

      it "should have 3 passengers" do
        subject.passengers.size.should == 3
      end

      it "should have 3 passengers with specified names" do
        subject.passengers.first.name.should == 'Joe'
        subject.passengers.second.name.should == 'Sue'
        subject.passengers.third.name.should == 'Pat'
      end

      it "should save the children when saving the parent" do
        subject.save
        found_subject = Car.find(subject.key)
        found_subject.passengers.map(&:name).should =~ %w[ Joe Sue Pat ]
      end
    end

    describe "update" do
      let(:passenger1) { Passenger.create(:name => 'One') }
      let(:passenger2) { Passenger.create(:name => 'Two') }
      let(:passenger3) { Passenger.create(:name => 'Three') }

      before do
        subject.passengers << passenger1
        subject.passengers << passenger2
        subject.passengers << passenger3
        subject.save
      end

      it "should have 3 passengers" do
        subject.passengers.size.should == 3
      end

      it "should update attributes" do
        subject.passengers_attributes = [ { :key => passenger1.key, :name => 'UPDATED One' },
                                          { :key => passenger2.key, :name => 'UPDATED Two' },
                                          { :key => passenger3.key, :name => 'UPDATED Three' } ]
        subject.passengers.first.name.should == 'UPDATED One'
        subject.passengers.second.name.should == 'UPDATED Two'
        subject.passengers.third.name.should == 'UPDATED Three'
      end

      it "should not save the child if attributes haven't been updated" do
        subject.passengers.each do |passenger|
          passenger.should_not_receive(:save)
        end
        subject.save
      end

      it "should save the child when saving the parent" do
        subject.passengers_attributes = [ { :key => passenger1.key, :name => 'UPDATED One' },
                                          { :key => passenger2.key, :name => 'UPDATED Two' },
                                          { :key => passenger3.key, :name => 'UPDATED Three' } ]
        subject.save

        found_subject = Car.find(subject.key)
        found_subject.passengers.map(&:name).should =~ [
          'UPDATED One',
          'UPDATED Two',
          'UPDATED Three'
        ]
      end
    end
  end

  context "one :engine (embedded)" do
    subject { Car.new }

    it { should respond_to(:engine_attributes=) }

    it "should not have an engine" do
      subject.engine.should be_nil
    end

    describe "creation" do
      subject { Car.new(:make => 'VW', :model => 'Rabbit', :engine_attributes => { :displacement => '2.5L' }) }

      it "should have an engine of class Engine" do
        subject.engine.should be_a(Engine)
      end

      it "should have a engine with displacement '2.5L'" do
        subject.engine.displacement.should == '2.5L'
      end

      it "should save the child when saving the parent" do
        subject.engine.should_not_receive(:save)
        subject.save
      end
    end

    describe "update" do
      before do
        subject.engine.build(:displacement => '3.6L')
        subject.save
      end

      it "should have a specified engine" do
        subject.engine.displacement.should == '3.6L'
      end

      it "should update attributes" do
        subject.engine_attributes = { :displacement => 'UPDATED 3.6L' }
        subject.engine.displacement.should == 'UPDATED 3.6L'
      end

      it "should not save the child if attributes haven't been updated" do
        subject.engine.should_not_receive(:save)
        subject.save
      end

      it "should not save the child when saving the parent" do
        subject.engine_attributes = { :displacement => 'UPDATED 3.6L' }
        subject.engine.should_not_receive(:save)
        subject.save
      end
    end
  end

  context "many :seats (embedded)" do
    subject { Car.new }

    it { should respond_to(:seats_attributes=) }

    it "should not have passengers" do
      subject.seats.should == []
    end

    describe "creation" do
      subject { Car.new(:make => 'VW',
                        :model => 'Rabbit',
                        :seats_attributes => [ { :color => 'red' },
                                               { :color => 'blue' },
                                               { :color => 'brown' } ] ) }

      it "should have 3 seats" do
        subject.seats.size.should == 3
      end

      it "should have 3 passengers with specified names" do
        subject.seats.first.color.should == 'red'
        subject.seats.second.color.should == 'blue'
        subject.seats.third.color.should == 'brown'
      end

      specify "replace/clobber" do
        subject.seats_attributes = [ { :color => 'orange' } ]
        subject.seats.size.should == 1
        subject.seats.first.color.should == 'orange'
      end

    end
  end

  context ":reject_if" do
    it "should not create a wheel" do
      car = Car.new(:wheels_attributes => [ { :diameter => 10 } ])
      car.wheels.should == []
    end

    it "should create a wheel" do
      car = Car.new(:wheels_attributes => [ { :diameter => 16 } ])
      car.wheels.size.should == 1
      car.wheels.first.diameter.should == 16
    end
  end

  context ":allow_delete" do
    let(:wheel) { Wheel.create(:diameter => 17) }
    subject { Car.create(:wheels => [ wheel ] ) }

    it "should allow us to delete the wheel" do
      subject.wheels_attributes = [ { :key => wheel.key, :_destroy => "1" } ]
      subject.save
      subject.wheels.should == []
    end

  end

end
