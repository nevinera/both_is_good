module BothIsGood
  class LocalConfiguration < Configuration
    LOCAL_ATTRIBUTES = %i[original replacement comparator].freeze

    attr_reader(*LOCAL_ATTRIBUTES)

    def initialize(base_config, owner:, original:, replacement:, **opts)
      comparator = opts.delete(:comparator)
      super(base_config, **opts)
      @original = validated_method(owner, :original, original)
      @replacement = validated_method(owner, :replacement, replacement)
      @comparator = validated_comparator(comparator)
    end

    private

    def validated_method(owner, role, name)
      raise ArgumentError, "#{role} must not be nil" if name.nil?
      unless owner.method_defined?(name) || owner.private_method_defined?(name)
        raise ArgumentError, "#{role} method #{name.inspect} is not defined on #{owner}"
      end
      name
    end

    def validated_comparator(value)
      return nil if value.nil?
      return validated_comparator_class(value) if value.is_a?(Class)
      unless value.respond_to?(:call) && value.arity == 2
        raise ArgumentError, "comparator must be nil, callable with arity 2, or a class with initialize(a, b) and call"
      end
      value
    end

    def validated_comparator_class(klass)
      unless klass.method_defined?(:call) && klass.instance_method(:call).arity == 0
        raise ArgumentError, "comparator class must define a zero-arity call instance method"
      end
      unless klass.instance_method(:initialize).arity == 2
        raise ArgumentError, "comparator class must define initialize with arity 2"
      end
      klass
    end
  end
end
