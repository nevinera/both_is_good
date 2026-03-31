module BothIsGood
  def self.configuration = Configuration.global

  def self.configure = yield(configuration)

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def both_is_good_configure(base = nil, **overrides)
      @both_is_good_configuration =
        if base
          Configuration.new(base, **overrides)
        else
          Configuration.new(**overrides)
        end
    end

    def both_is_good_configuration
      @both_is_good_configuration || BothIsGood.configuration
    end

    def implemented_twice(name, primary:, secondary:, **opts)
      if name == primary
        alias_method :"_bothisgood_primary_#{name}", name
        primary = :"_bothisgood_primary_#{name}"
      end

      if name == secondary
        alias_method :"_bothisgood_secondary_#{name}", name
        secondary = :"_bothisgood_secondary_#{name}"
      end

      runner = ImplementedTwice.new(primary: primary, secondary: secondary, **opts)

      define_method(name) do |*args, **kwargs|
        runner.call(self, *args, **kwargs)
      end
    end
  end
end

require_relative "both_is_good/version"
require_relative "both_is_good/configuration"
require_relative "both_is_good/memoization"
require_relative "both_is_good/invocation"
require_relative "both_is_good/implemented_twice"
