require 'tzinfo'
require 'active_support/core_ext/date/conversions'
require 'active_support/core_ext/date/zones'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/core_ext/date_time/zones'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/time/zones'
require 'active_support/core_ext/string/conversions'
require 'ripple/property_type_mismatch'
require 'set'

# @private
class Object
  def to_ripple_index(type)
    case type
    when 'bin'
      to_s
    when 'int'
      to_i
    end
  end
end

# @private
class Time
  def to_ripple_index(type)
    case type
    when 'bin'
      utc.send(Ripple.date_format)
    when 'int'
      # Use millisecond-precision
      (utc.to_f * 1000).round
    end
  end
end

# @private
class Date
  def to_ripple_index(type)
    case type
    when 'bin'
      to_s(Ripple.date_format)
    when 'int'
      to_time(:utc).to_ripple_index(type)
    end
  end
end

# @private
class DateTime
  def to_ripple_index(type)
    case type
    when 'bin'
      utc.to_s(Ripple.date_format)
    when 'int'
      (utc.to_f * 1000).round
    end
  end
end

# @private
module ActiveSupport
  class TimeWithZone
    def to_ripple_index(type)
      utc.to_ripple_index(type)
    end
  end
end

# @private
module Enumerable
  def to_ripple_index(type)
    Set.new(map {|v| v.to_ripple_index(type) })
  end
end
