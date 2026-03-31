module BothIsGood
  class Invocation
    include BothIsGood::Memoization

    def initialize(local_config, target, args, kwargs)
      @config = local_config
      @target = target
      @args = args
      @kwargs = kwargs
      @memo = {}
    end

    def run
      invoke_primary!
      invoke_secondary! if trigger?
      primary_result
    end

    private

    memoize def primary = @config.primary
    memoize def secondary = @config.secondary

    memoize def trigger? = rand < @config.rate

    def invoke_primary!
      primary_result
    rescue => e
      on_primary_error(e)
      raise
    end

    def invoke_secondary!
      secondary_result
    rescue => e
      on_secondary_error(e)
    else
      on_secondary_success
    end

    memoize def primary_result = @target.send(@config.primary, *@args, **@kwargs)
    memoize def secondary_result = @target.send(@config.secondary, *@args, **@kwargs)

    def on_primary_error(error)
      hook = @config.on_primary_error
      with_hook_error_handling { invoke_error_hook(hook, error, primary) } if hook
    end

    def on_secondary_error(error)
      return unless @config.on_secondary_error

      with_hook_error_handling do
        invoke_error_hook(@config.on_secondary_error, error, secondary)
      end
    end

    def on_secondary_success
      matched = compare(primary_result, secondary_result)
      on_compare
      on_mismatch unless matched
    end

    def on_compare
      return unless @config.on_compare

      with_hook_error_handling do
        invoke_result_hook(@config.on_compare, primary_result, secondary_result)
      end
    end

    def on_mismatch
      return unless @config.on_mismatch

      with_hook_error_handling do
        invoke_result_hook(@config.on_mismatch, primary_result, secondary_result)
      end
    end

    def with_hook_error_handling
      yield
    rescue => e
      @config.on_hook_error&.call(e)
    end

    def compare(primary_result, secondary_result)
      comparator = @config.comparator
      comparator ? comparator.call(primary_result, secondary_result) : primary_result == secondary_result
    end

    memoize def names = {primary:, secondary:}
    memoize def call_args = @kwargs.empty? ? @args : [*@args, @kwargs]

    def invoke_result_hook(hook, primary_result, secondary_result)
      case hook.arity
      when 2 then hook.call(primary_result, secondary_result)
      when 3 then hook.call(primary_result, secondary_result, names)
      else hook.call(primary_result, secondary_result, call_args, names)
      end
    end

    def invoke_error_hook(hook, error, method_name)
      case hook.arity
      when 1 then hook.call(error)
      when 2 then hook.call(error, call_args)
      else hook.call(error, call_args, method_name)
      end
    end
  end
end
