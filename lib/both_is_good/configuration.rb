module BothIsGood
  class Configuration
    DEFAULTS = {
      rate: 1.0,
      switch: nil,
      on_mismatch: nil,
      on_compare: nil,
      on_primary_error: nil,
      on_secondary_error: nil,
      on_hook_error: nil
    }.freeze

    ATTRIBUTES = DEFAULTS.keys.freeze
    UNSUPPLIED = Object.new.freeze

    attr_reader(*ATTRIBUTES)

    def self.global
      @global ||= new(nil, **DEFAULTS)
    end

    def initialize(supplied_base = UNSUPPLIED, **overrides)
      base = base_config(supplied_base)
      apply_initial_values(base, **overrides)
    end

    def dup = self.class.new(self)

    def rate=(value)
      unless value.is_a?(Numeric) && (0.0..1.0).cover?(value)
        raise ArgumentError, "rate must be a number between 0.0 and 1.0, got #{value.inspect}"
      end
      @rate = value
    end

    def switch=(value)
      validate_hook!(:switch, value, [0, 1])
      @switch = value
    end

    def on_mismatch=(value)
      validate_hook!(:on_mismatch, value, [1])
      @on_mismatch = value
    end

    def on_compare=(value)
      validate_hook!(:on_compare, value, [1])
      @on_compare = value
    end

    def on_primary_error=(value)
      validate_hook!(:on_primary_error, value, [1, 2, 3])
      @on_primary_error = value
    end

    def on_secondary_error=(value)
      validate_hook!(:on_secondary_error, value, [1, 2, 3])
      @on_secondary_error = value
    end

    def on_hook_error=(value)
      validate_hook!(:on_hook_error, value, [1])
      @on_hook_error = value
    end

    private

    def validate_hook!(name, value, valid_arities)
      return if value.nil?

      unless value.respond_to?(:call) && valid_arities.include?(value.arity)
        raise ArgumentError, "#{name} must be nil or callable with arity in #{valid_arities.inspect}"
      end
    end

    def base_config(supplied_base)
      if supplied_base == UNSUPPLIED
        Configuration.global
      else
        supplied_base
      end
    end

    def initial_value_for(base, attr:, default:, overrides:)
      if overrides.key?(attr)
        overrides[attr]
      elsif base
        base.public_send(attr)
      else
        default
      end
    end

    def apply_initial_values(base, **overrides)
      DEFAULTS.each_pair do |attr, default|
        public_send(:"#{attr}=", initial_value_for(base, attr:, default:, overrides:))
      end
    end
  end
end
