class Timeseries
  include Ripple::Document
  property :date, Date
  property :column, String

  def key
    "#{column}-#{date}"
  end
end
