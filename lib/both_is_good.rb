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

      primary_name = primary
      secondary_name = secondary
      rate = opts.fetch(:rate, 1.0)
      comparator = opts.fetch(:comparator, nil)

      define_method(name) do |*args, **kwargs|
        primary_result = send(primary_name, *args, **kwargs)
        if rand < rate
          secondary_result = send(secondary_name, *args, **kwargs)
          comparator ? comparator.call(primary_result, secondary_result) : primary_result == secondary_result
        end
        primary_result
      end
    end
  end
end

require_relative "both_is_good/version"
require_relative "both_is_good/configuration"
