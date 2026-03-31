module BothIsGood
  class ImplementedTwice
    def initialize(primary:, secondary:, **opts)
      @primary = primary
      @secondary = secondary
      @rate = opts.fetch(:rate, 1.0)
      @comparator = opts.fetch(:comparator, nil)
      @on_compare = validated_result_hook(:on_compare, opts.fetch(:on_compare, nil))
      @on_mismatch = validated_result_hook(:on_mismatch, opts.fetch(:on_mismatch, nil))
      @on_secondary_error = validated_error_hook(:on_secondary_error, opts.fetch(:on_secondary_error, nil))
    end

    def call(target, *args, **kwargs)
      primary_result = target.send(@primary, *args, **kwargs)
      if rand < @rate
        begin
          secondary_result = target.send(@secondary, *args, **kwargs)
        rescue => e
          on_secondary_error(e, args, kwargs)
        else
          on_secondary_success(primary_result, secondary_result, args, kwargs)
        end
      end
      primary_result
    end

    private

    def on_secondary_error(error, args, kwargs)
      invoke_error_hook(@on_secondary_error, error, args, kwargs, @secondary) if @on_secondary_error
    end

    def on_secondary_success(primary_result, secondary_result, args, kwargs)
      matched = compare(primary_result, secondary_result)
      invoke_result_hook(@on_compare, primary_result, secondary_result, args, kwargs) if @on_compare
      invoke_result_hook(@on_mismatch, primary_result, secondary_result, args, kwargs) if @on_mismatch && !matched
    end

    def compare(primary_result, secondary_result)
      @comparator ? @comparator.call(primary_result, secondary_result) : primary_result == secondary_result
    end

    def names = {primary: @primary, secondary: @secondary}

    def call_args(args, kwargs) = kwargs.empty? ? args : [*args, kwargs]

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

    def invoke_result_hook(hook, primary_result, secondary_result, args, kwargs)
      case hook.arity
      when 2 then hook.call(primary_result, secondary_result)
      when 3 then hook.call(primary_result, secondary_result, names)
      else hook.call(primary_result, secondary_result, call_args(args, kwargs), names)
      end
    end

    def invoke_error_hook(hook, error, args, kwargs, method_name)
      case hook.arity
      when 1 then hook.call(error)
      when 2 then hook.call(error, call_args(args, kwargs))
      else hook.call(error, call_args(args, kwargs), method_name)
      end
    end
  end
end
