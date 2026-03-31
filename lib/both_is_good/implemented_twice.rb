module BothIsGood
  class ImplementedTwice
    def initialize(primary:, secondary:, **opts)
      @primary = primary
      @secondary = secondary
      @rate = opts.fetch(:rate, 1.0)
      @comparator = opts.fetch(:comparator, nil)
      @on_compare = opts.fetch(:on_compare, nil)
    end

    def call(target, *args, **kwargs)
      primary_result = target.send(@primary, *args, **kwargs)
      if rand < @rate
        secondary_result = target.send(@secondary, *args, **kwargs)
        compare(primary_result, secondary_result)
        invoke_result_hook(@on_compare, primary_result, secondary_result, args, kwargs) if @on_compare
      end
      primary_result
    end

    private

    def compare(primary_result, secondary_result)
      @comparator ? @comparator.call(primary_result, secondary_result) : primary_result == secondary_result
    end

    def names = {primary: @primary, secondary: @secondary}

    def call_args(args, kwargs) = kwargs.empty? ? args : [*args, kwargs]

    def invoke_result_hook(hook, primary_result, secondary_result, args, kwargs)
      case hook.arity
      when 2 then hook.call(primary_result, secondary_result)
      when 3 then hook.call(primary_result, secondary_result, names)
      when 4 then hook.call(primary_result, secondary_result, call_args(args, kwargs), names)
      end
    end
  end
end
