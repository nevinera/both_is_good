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

    memoize def switched?
      if @config.switch.nil?
        false
      elsif @config.switch.arity == 0
        @config.switch.call
      else
        @config.switch.call(BothIsGood::Context::Switching.new(@target.target_class, @target.method_name))
      end
    end

    memoize def primary = switched? ? @config.replacement : @config.original
    memoize def secondary = switched? ? @config.original : @config.replacement

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

    memoize def primary_result = @target.instance.send(primary, *@args, **@kwargs)
    memoize def secondary_result = @target.instance.send(secondary, *@args, **@kwargs)

    def on_primary_error(error)
      hook = @config.on_primary_error
      with_hook_error_handling { hook.call(error_context(error, primary)) } if hook
    end

    def on_secondary_error(error)
      return unless @config.on_secondary_error

      with_hook_error_handling do
        @config.on_secondary_error.call(error_context(error, secondary))
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
        @config.on_compare.call(result_context)
      end
    end

    def on_mismatch
      return unless @config.on_mismatch

      with_hook_error_handling do
        @config.on_mismatch.call(result_context)
      end
    end

    def with_hook_error_handling
      yield
    rescue => e
      if @config.on_hook_error
        @config.on_hook_error.call(e)
      else
        raise
      end
    end

    def compare(primary_result, secondary_result)
      comparator = @config.comparator
      comparator ? comparator.call(primary_result, secondary_result) : primary_result == secondary_result
    end

    memoize def names = {primary:, secondary:}
    memoize def call_args = @kwargs.empty? ? @args : [*@args, @kwargs]

    memoize def result_context
      BothIsGood::Context::Result.new(
        target: @target,
        args: call_args,
        primary_result:,
        secondary_result:,
        names:
      )
    end

    def error_context(error, dispatched_name)
      BothIsGood::Context::Error.new(
        target: @target,
        args: call_args,
        error:,
        dispatched_name:
      )
    end
  end
end
