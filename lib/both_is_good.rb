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
  end
end

require_relative "both_is_good/version"
require_relative "both_is_good/configuration"
