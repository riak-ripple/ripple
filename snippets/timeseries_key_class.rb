class TimeseriesKey
  attr_accessor :column, :user_key
  attr_reader :date

  # http://en.wikipedia.org/wiki/Record_separator#Field_separators
  UNIT_SEPARATOR = "\x1f"

  def initialize(opts)
    initialize_from_key(opts) if opts.is_a? String

    # the implementation of this is left as an exercise for the reader
    initialize_from_options(opts) if opts.is_a? Hash
  end

  def initialize_from_key(opts)
    self.date, self.column, self.user_key = opts.split(UNIT_SEPARATOR)
  end

  def date=(new_date)
    # coerce new_date to the appropriate type
  end

  def to_s
    [date, column, user_key].join UNIT_SEPARATOR
  end
end

class Timeseries
  include Ripple::Document
  property :date, Date
  property :column, String
  one :user, using: :stored_key

  def key
    @key ||= TimeseriesKey.new(attributes).to_s
  end
end
