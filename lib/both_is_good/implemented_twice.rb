module BothIsGood
  class ImplementedTwice
    def initialize(primary:, secondary:, **opts)
      @primary = primary
      @secondary = secondary
      @rate = opts.fetch(:rate, 1.0)
      @comparator = opts.fetch(:comparator, nil)
    end

    def call(target, *args, **kwargs)
      primary_result = target.send(@primary, *args, **kwargs)
      if rand < @rate
        secondary_result = target.send(@secondary, *args, **kwargs)
        compare(primary_result, secondary_result)
      end
      primary_result
    end

    private

    def compare(primary_result, secondary_result)
      @comparator ? @comparator.call(primary_result, secondary_result) : primary_result == secondary_result
    end
  end
end
