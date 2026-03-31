module BothIsGood
  class LocalConfiguration < Configuration
    LOCAL_ATTRIBUTES = %i[primary secondary comparator].freeze

    attr_reader(*LOCAL_ATTRIBUTES)

    def initialize(owner, primary:, secondary:, comparator: nil, **opts)
      super(nil, **opts)
      @primary = validated_method(owner, :primary, primary)
      @secondary = validated_method(owner, :secondary, secondary)
      @comparator = validated_comparator(comparator)
    end

    private

    def validated_method(owner, role, name)
      raise ArgumentError, "#{role} must not be nil" if name.nil?
      unless owner.method_defined?(name)
        raise ArgumentError, "#{role} method #{name.inspect} is not defined on #{owner}"
      end
      name
    end

    def validated_comparator(value)
      return nil if value.nil?
      unless value.respond_to?(:call) && value.arity == 2
        raise ArgumentError, "comparator must be nil or callable with arity 2"
      end
      value
    end
  end
end
