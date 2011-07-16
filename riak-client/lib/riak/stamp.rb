require 'riak/client'
require 'riak/util/translation'
require 'thread'

module Riak
  # Implements a client-side form of monotonically-increasing k-sorted
  # unique identifiers.  These are useful for key generation if your
  # data is time-sequential and needs to be sorted by key, perhaps in
  # Riak Search. Inspired by Twitter's Snowflake project.
  class Stamp
    attr_reader :client

    CLIENT_ID_MASK = 0x3f
    SEQUENCE_MASK = 0x0aff
    TIMESTAMP_MASK = 0x3ffffffffff
    SEQUENCE_SHIFT = 10
    TIMESTAMP_SHIFT = 22

    # @param [Client] client a {Riak::Client} which will be used for
    #   the "worker ID" component of the stamp.
    # @see Client#stamp
    def initialize(client)
      @client = client
      @mutex = Mutex.new
      @timestamp = timestamp
      @sequence = 0
    end

    # Generates a k-sorted unique ID for use as a key or other
    # disambiguation purposes.
    def next
      @mutex.synchronize do
        new_stamp = timestamp
        if @timestamp == new_stamp
          @sequence += 1 & SEQUENCE_MASK
          new_stamp = wait_for_next_ms(@timestamp) if @sequence == 0
        else
          @sequence = 0
        end

        raise BackwardsClockError.new(@timestamp - new_stamp) if new_stamp < @timestamp

        @timestamp = new_stamp
        @timestamp << TIMESTAMP_SHIFT | @sequence << SEQUENCE_SHIFT | client_id
      end
    end

    private
    def client_id
      case id = @client.client_id
      when Integer
        id & CLIENT_ID_MASK
      else
        id.hash & CLIENT_ID_MASK
      end
    end

    def timestamp
      (Time.now.to_f * 1000).floor & TIMESTAMP_MASK
    end
  end

  # Raised when calling {Stamp#next} and NTP or some other external
  # event has moved the system clock backwards.
  class BackwardsClockError < StandardError
    include Util::Translation
    def initialize(delay)
      super t('backwards_clock', :delay => delay)
    end
  end
end
