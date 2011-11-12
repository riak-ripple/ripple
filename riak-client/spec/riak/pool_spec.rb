require 'spec_helper'
require 'thread'

describe Riak::Client::Pool do
  describe 'arrays of ints' do
    subject { described_class.new(
                                  lambda { [0] },
                                  lambda { |x| }
                                  )}

    it 'yields a new object' do
      subject.take do |x|
        x.should == [0]
      end
    end

    it 'retains a single object for serial access' do
      n = 100
      n.times do |i|
        subject.take do |x|
          x.should == [i]
          x[0] += 1
        end
      end
      subject.size.should == 1
    end

    it 'should be re-entrant' do
      n = 10
      n.times do |i|
        subject.take do |x|
          x.replace [1]
          subject.take do |y|
            y.replace [2]
            subject.take do |z|
              z.replace [3]
              subject.take do |t|
                t.replace [4]
              end
            end
          end
        end
      end
      subject.pool.map { |e| e.object.first }.sort.should == [1,2,3,4]
    end

    it 'should unlock when exceptions are raised' do
      begin
        subject.take do |x|
          x << 1
          subject.take do |y|
            x << 2
            y << 3
            raise
          end
        end
      rescue
      end
      subject.pool.all? { |e| not e.owner }.should == true
      subject.pool.map { |e| e.object }.to_set.should == [
                                                          [0,1,2],
                                                          [0,3]
                                                         ].to_set
    end
  end

  describe 'threads' do
    subject { described_class.new(
                                  lambda { [] },
                                  lambda { |x| }
                                  )}

    it 'should allocate n objects for n concurrent operations' do
      n = 10
      # n threads concurrently allocate and sign objects from the pool
      readyq = Queue.new
      finishq = Queue.new
      threads = (0...n).map do
        Thread.new do
          subject.take do |x|
            readyq << 1
            x << Thread.current
            finishq.pop
          end
        end
      end

      n.times { readyq.pop }
      n.times { finishq << 1 }

      # Wait for completion
      threads.each do |t|
        t.join
      end

      # Should have taken exactly n objects to do this
      subject.size.should == n
      # And each one should be signed exactly once
      subject.pool.map do |e|
        e.object.size.should == 1
        e.object.first
      end.to_set.should == threads.to_set
    end

    it 'stress test', :slow => true do
      n = 100
      psleep = 0.8
      tsleep = 0.01
      rounds = 100

      threads = (0...n).map do
        Thread.new do
          rounds.times do |i|
            subject.take do |a|
              a.should == []
              a << Thread.current
              a.should == [Thread.current]

              # Sleep and check
              while rand < psleep
                sleep tsleep
                a.should == [Thread.current]
              end

              a.delete Thread.current
            end
          end
        end
      end
      threads.each do |t|
        t.join
      end
    end
  end
end
