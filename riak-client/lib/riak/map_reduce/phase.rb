
require 'riak/json'
require 'riak/util/translation'
require 'riak/walk_spec'

module Riak
  class MapReduce
    # Represents an individual phase in a map-reduce pipeline. Generally you'll want to call
    # methods of MapReduce instead of using this directly.
    class Phase
      include Util::Translation
      # @return [Symbol] the type of phase - :map, :reduce, or :link
      attr_accessor :type

      # @return [String, Array<String, String>, Hash, WalkSpec] For :map and :reduce types, the Javascript function to run (as a string or hash with bucket/key), or the module + function in Erlang to run. For a :link type, a {Riak::WalkSpec} or an equivalent hash.
      attr_accessor :function

      # @return [String] the language of the phase's function - "javascript" or "erlang". Meaningless for :link type phases.
      attr_accessor :language

      # @return [Boolean] whether results of this phase will be returned
      attr_accessor :keep

      # @return [Array] any extra static arguments to pass to the phase
      attr_accessor :arg

      # Creates a phase in the map-reduce pipeline
      # @param [Hash] options options for the phase
      # @option options [Symbol] :type one of :map, :reduce, :link
      # @option options [String] :language ("javascript") "erlang" or "javascript"
      # @option options [String, Array, Hash] :function In the case of Javascript, a literal function in a string, or a hash with :bucket and :key. In the case of Erlang, an Array of [module, function].  For a :link phase, a hash including any of :bucket, :tag or a WalkSpec.
      # @option options [Boolean] :keep (false) whether to return the results of this phase
      # @option options [Array] :arg (nil) any extra static arguments to pass to the phase
      def initialize(options={})
        self.type = options[:type]
        self.language = options[:language] || "javascript"
        self.function = options[:function]
        self.keep = options[:keep] || false
        self.arg = options[:arg]
      end

      def type=(value)
        raise ArgumentError, t("invalid_phase_type") unless value.to_s =~ /^(map|reduce|link)$/i
        @type = value.to_s.downcase.to_sym
      end

      def function=(value)
        case value
        when Array
          raise ArgumentError, t("module_function_pair_required") unless value.size == 2
          @language = "erlang"
        when Hash
          raise ArgumentError, t("stored_function_invalid") unless type == :link || value.has_key?(:bucket) && value.has_key?(:key)
          @language = "javascript"
        when String
          @language = "javascript"
        when WalkSpec
          raise ArgumentError, t("walk_spec_invalid_unless_link") unless type == :link
        else
          raise ArgumentError, t("invalid_function_value", :value => value.inspect)
        end
        @function = value
      end

      # Converts the phase to JSON for use while invoking a job.
      # @return [String] a JSON representation of the phase
      def to_json(*a)
        as_json.to_json(*a)
      end

      # Converts the phase to its JSON-compatible representation for job invocation.
      # @return [Hash] a Hash-equivalent of the phase
      def as_json(options=nil)
        obj = case type
              when :map, :reduce
                defaults = {"language" => language, "keep" => keep}
                case function
                when Hash
                  defaults.merge(function)
                when String
                  if function =~ /\s*function/
                    defaults.merge("source" => function)
                  else
                    defaults.merge("name" => function)
                  end
                when Array
                  defaults.merge("module" => function[0], "function" => function[1])
                end
              when :link
                spec = WalkSpec.normalize(function).first
                {"bucket" => spec.bucket, "tag" => spec.tag, "keep" => spec.keep || keep}
              end
        obj["arg"] = arg if arg
        { type => obj }
      end
    end
  end
end
