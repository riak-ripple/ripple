require 'rubygems'
require 'riak'
require 'riakpb'

class Riak::Client
  attr_accessor :pb_port
end

class PB
  include Riak::Client::Protobufs
end

if __FILE__ == $PROGRAM_NAME
  require 'benchmark'
  c = Riak::Client.new
  c.pb_port = 8087
  pb = PB.new(c)
  Benchmark.bmbm(25) do |x|
    x.report("get_bucket PB") { 1000.times {|i| pb.get_bucket("foo#{i}") } }
    x.report("get_bucket HTTP") { 1000.times {|i| ActiveSupport::JSON.decode(c.http.get(200, "/riak", "foo#{i}", {})[:body]) } }

    
  end
else
  $c = Riak::Client.new
  $c.pb_port = 8087
  $pb = PB.new($c)
end
