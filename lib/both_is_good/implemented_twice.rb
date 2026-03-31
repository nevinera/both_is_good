module BothIsGood
  class ImplementedTwice
    def initialize(owner, primary:, secondary:, **opts)
      @local_config = LocalConfiguration.new(owner, primary:, secondary:, **opts)
    end

    def call(target, *args, **kwargs)
      Invocation.new(@local_config, target, args, kwargs).run
    end
  end
end
