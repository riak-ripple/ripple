class Riak::Client::Decaying
  # A float which decays exponentially with time.

  attr_accessor :e
  attr_accessor :p
  # @param[:p] The initial value
  # @param[:e] Exponent base
  # @param[:r] Timescale
  def initialize(opts = {})
    @p = opts[:p] || 0
    @e = opts[:e] || Math::E
    @r = opts[:r] || Math.log(0.5) / 10
    @t0 = Time.now
  end

  # Add d to current value.
  def <<(d)
    @p = value + d
  end

  # Return current value
  def value
    now = Time.now
    dt = now - @t0
    @t0 = now
    @p = @p * (@e ** (@r * dt))
  end
end
