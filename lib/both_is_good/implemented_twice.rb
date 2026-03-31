module BothIsGood
  class ImplementedTwice
    def initialize(primary:, secondary:, **opts)
      @config = {
        primary: primary,
        secondary: secondary,
        rate: opts.fetch(:rate, 1.0),
        comparator: opts.fetch(:comparator, nil),
        on_compare: validated_result_hook(:on_compare, opts.fetch(:on_compare, nil)),
        on_mismatch: validated_result_hook(:on_mismatch, opts.fetch(:on_mismatch, nil)),
        on_secondary_error: validated_error_hook(:on_secondary_error, opts.fetch(:on_secondary_error, nil))
      }.freeze
    end

    def call(target, *args, **kwargs)
      Invocation.new(@config, target, args, kwargs).run
    end

    private

    def validated_result_hook(name, hook)
      return nil if hook.nil?
      unless hook.respond_to?(:call) && [2, 3, 4].include?(hook.arity)
        raise ArgumentError, "#{name} must be callable with arity 2, 3, or 4"
      end
      hook
    end

    def validated_error_hook(name, hook)
      return nil if hook.nil?
      unless hook.respond_to?(:call) && [1, 2, 3].include?(hook.arity)
        raise ArgumentError, "#{name} must be callable with arity 1, 2, or 3"
      end
      hook
    end
  end
end
