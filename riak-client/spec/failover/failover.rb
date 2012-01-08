$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../../lib')
require 'riak'

# This is not a formal spec yet. It's designed to be run agains a local dev
# cluster while you bring nodes up and down.
[
  {:protocol => 'pbc', :protobuffs_backend => :Beefcake},
  {:protocol => 'http', :http_backend => :NetHTTP},
  {:protocol => 'http', :http_backend => :Excon}
].each do |opts|
  @client = Riak::Client.new(
    {
      :nodes => (1..3).map { |i|
        {
          :http_port => 8090 + i,
          :pb_port => 8080 + i
        }
      }
    }.merge(opts)
  )

  errors = []
  p opts

  n = 10
  c = 1000

  (0...n).map do |t|
    Thread.new do
      # Generate a stream of put reqs. Put a . for each success, an X for
      # each failure.
      c.times do |i|
        begin
          o = @client['test'].new("#{t}:#{i}")
          o.content_type = 'text/plain'
          o.data = i.to_s
          o.store
          o2 = @client['test'].get("#{t}:#{i}")
          o2.data == i.to_s or raise "wrong data"
          print '.'
        rescue => e
          print 'X'
          errors << e
        end
      end
    end
  end.each do |thread|
    thread.join
  end

  # Put errors
  puts
  errors.each do |e|
    puts e.inspect
    puts e.backtrace.map { |x| "  #{x}" }.join("\n")
  end

  puts "\n\n"
end
