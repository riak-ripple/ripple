require 'active_support/json'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_json'
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
  def self.ripple_cast(value)
    value
  end
end

# @private
class Symbol
  def self.ripple_cast(value)
    return nil if value.blank?
    value.respond_to?(:to_s) && value.to_s.intern or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

# @private
class Numeric
  def self.ripple_cast(value)
    return nil if value.blank?
    raise Ripple::PropertyTypeMismatch.new(self,value) unless value.respond_to?(:to_i) && value.respond_to?(:to_f)
    float_value = value.to_f
    int_value = value.to_i
    float_value == int_value ? int_value : float_value
  end
end

# @private
class Integer
  def self.ripple_cast(value)
    return nil if value.nil? || (String === value && value.blank?)
    !value.is_a?(Symbol) && value.respond_to?(:to_i) && value.to_i or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

# @private
class Float
  def self.ripple_cast(value)
    return nil if value.nil? || (String === value && value.blank?)
    value.respond_to?(:to_f) && value.to_f or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

# @private
class String
  def self.ripple_cast(value)
    return nil if value.nil?
    value.respond_to?(:to_s) && value.to_s or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

BooleanCast = Module.new do
  def ripple_cast(value)
    case value
    when NilClass
      nil
    when Numeric
      !value.zero?
    when TrueClass, FalseClass
      value
    when /^\s*t/i
      true
    when /^\s*f/i
      false
    else
      value.present?
    end
  end
end

unless defined?(::Boolean)
  # Stand-in for true/false property types.
  module ::Boolean; end
end

::Boolean.send(:extend, BooleanCast)
TrueClass.send(:extend, BooleanCast)
FalseClass.send(:extend, BooleanCast)

# @private
class Time
  def as_json(options={})
    self.utc.send(Ripple.date_format)
  end

  def self.ripple_cast(value)
    return nil if value.blank?
    value.respond_to?(:to_time) && value.to_time or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

# @private
class Date
  def as_json(options={})
    self.to_s(Ripple.date_format)
  end

  def self.ripple_cast(value)
    return nil if value.blank?
    value.respond_to?(:to_date) && value.to_date or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

# @private
class DateTime
  def as_json(options={})
    self.utc.to_s(Ripple.date_format)
  end

  def self.ripple_cast(value)
    return nil if value.blank?
    value.respond_to?(:to_datetime) && value.to_datetime or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

# @private
module ActiveSupport
  class TimeWithZone
    def as_json(options={})
      self.utc.send(Ripple.date_format)
    end
  end
end

# @private
class Set
  def as_json(options = {})
    map { |e| e.as_json(options) }
  end

  def self.ripple_cast(value)
    return nil if value.nil?
    value.is_a?(Enumerable) && new(value) or raise Ripple::PropertyTypeMismatch.new(self, value)
  end
end

