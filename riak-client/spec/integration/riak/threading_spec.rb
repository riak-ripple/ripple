require 'spec_helper'

describe "Multithreaded client", :test_server => true do
  class Synchronizer
    def initialize(n)
      @mutex = Mutex.new
      @n = n
      @waiting = Set.new
    end

    def sync
      stop = false
      @mutex.synchronize do
        @waiting << Thread.current

        if @waiting.size >= @n
          # All threads are waiting.
          @waiting.each do |t|
            t.run
          end
        else
          stop = true
        end
      end

      if stop
        Thread.stop
      end
    end
  end

  def threads(n, opts = {})
    if opts[:synchronize]
      s1 = Synchronizer.new n
      s2 = Synchronizer.new n
    end

    threads = (0...n).map do |i|
      Thread.new do
        if opts[:synchronize]
          s1.sync
        end

        yield i

        if opts[:synchronize]
          s2.sync
        end
      end
    end

    threads.each do |t|
      t.join
    end
  end

  [
    {:protocol => 'pbc', :protobuffs_backend => :Beefcake},
    {:protocol => 'http', :http_backend => :NetHTTP},
    {:protocol => 'http', :http_backend => :Excon}
  ].each do |opts|
    describe opts.inspect do
      before do
        @pb_port ||= $test_server.pb_port
        @http_port ||= $test_server.http_port
        @client = Riak::Client.new({
          :pb_port => @pb_port,
          :http_port => @http_port
        }.merge(opts))
      end

      it 'should get in parallel' do
        data = "the gun is good"
        ro = @client['test'].new('test')
        ro.content_type = "application/json"
        ro.data = [data]
        ro.store

        threads 10, :synchronize => true do
          x = @client['test']['test']
          x.content_type.should == "application/json"
          x.data.should == [data]
        end
      end
      
      it 'should put in parallel' do
        data = "the tabernacle is indestructible and everlasting"

        n = 10
        threads n, :synchronize => true do |i|
          x = @client['test'].new("test-#{i}")
          x.content_type = "application/json"
          x.data = ["#{data}-#{i}"]
          x.store
        end
        
        (0...n).each do |i|
          read = @client['test']["test-#{i}"]
          read.content_type.should == "application/json"
          read.data.should == ["#{data}-#{i}"]
        end
      end
      
      it 'should put conflicts in parallel' do
        @client['test'].allow_mult = true
        @client['test'].allow_mult.should == true
        
        init = @client['test'].new('test')
        init.content_type = "application/json"
        init.data = ''
        init.store

        # Create conflicting writes
        n = 10
        s = Synchronizer.new n
        threads n, :synchronize => true do |i|
          x = @client['test']["test"]
          s.sync
          x.data = [i]
          x.store
        end
        
        read = @client['test']["test"]
        read.conflict?.should == true
        read.siblings.map do |sibling|
          sibling.data.first
        end.to_set.should == (0...n).to_set
      end

      it 'should list-keys and get in parallel', :slow => true do
        count = 100
        threads = 2

        # Create items
        count.times do |i|
          o = @client['test'].new("#{i}")
          o.content_type = 'application/json'
          o.data = [i]
          o.store
        end
        
        threads(threads) do
          set = Set.new
          @client['test'].keys do |stream|
            stream.each do |key|
              set.merge @client['test'][key].data
            end
          end
          set.should == (0...count).to_set
        end
      end

      it 'should mapreduce in parallel' do
        count = 10
        threads = 10

        # Create items
        count.times do |i|
          o = @client['test'].new("#{i}")
          o.content_type = 'application/json'
          o.data = i
          o.store
        end

        # Ze mapreduce
        threads(threads) do
          # Mapreduce
          (0...count).inject(Riak::MapReduce.new(@client)) do |mr, i|
            mr.add('test', i.to_s)
          end.map(%{function(v) {
            return [v.key];
          }}, :keep => true).run.map do |s|
            s.to_i
          end.to_set.should == (0...count).to_set
        end
      end
    end
  end
end
