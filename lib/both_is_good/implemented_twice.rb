module BothIsGood
  class ImplementedTwice
    def initialize(owner, primary:, secondary:, **opts)
      base = owner.both_is_good_configuration
      @local_config = LocalConfiguration.new(base, owner:, primary:, secondary:, **opts)
    end

    def call(target, *args, **kwargs)
      Invocation.new(@local_config, target, args, kwargs).run
    end
  end
end
