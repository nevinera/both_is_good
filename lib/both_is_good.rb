require_relative "both_is_good/memoization"
require_relative "both_is_good/target"

module BothIsGood
  def self.configuration = Configuration.global

  def self.configure = yield(configuration)

  def self.register_comparator(name, klass) = configuration.register_comparator(name, klass)

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

    def implemented_twice(*positional, original: nil, replacement: nil, **opts)
      implementer = DualImplementer.new(*positional, target: self, original:, replacement:, **opts)
      implementer.apply_aliases!
      runner = implementer.implementation

      define_method(implementer.name) do |*args, **kwargs|
        runner.call(BothIsGood::Target.new(self, implementer.name, self.class), *args, **kwargs)
      end
    end
  end

  class DualImplementer
    include Memoization

    def initialize(*positional, target:, original:, replacement:, **opts)
      @target = target
      @positional = positional
      @kw_original = original
      @kw_replacement = replacement
      @opts = opts

      validate!
    end

    attr_reader :positional, :target, :opts

    memoize def name = positional.first
    memoize def original = aliased_original? ? :"_bothisgood_original_#{name}" : supplied_original
    memoize def replacement = aliased_replacement? ? :"_bothisgood_replacement_#{name}" : supplied_replacement

    def apply_aliases!
      target.alias_method(original, name) if aliased_original?
      target.alias_method(replacement, name) if aliased_replacement?
    end

    memoize def implementation = ImplementedTwice.new(target, original:, replacement:, **opts)

    private

    memoize def supplied_original = @kw_original || positional[-2]
    memoize def supplied_replacement = @kw_replacement || positional.last

    memoize def aliased_original? = supplied_original == name
    memoize def aliased_replacement? = supplied_replacement == name

    def validate!
      validate_name_supplied!
      validate_replacement_supplied!
      validate_no_original_replacement_match!
      validate_no_mixing!
      validate_no_extra_positional!
    end

    def validate_name_supplied!
      return unless positional.empty?
      raise(ArgumentError, "the 'name' positional parameter is required")
    end

    def validate_replacement_supplied!
      return if @kw_replacement || positional.length >= 2
      raise ArgumentError, "replacement is required, either as a positional argument or as a keyword argument"
    end

    def validate_no_original_replacement_match!
      return if supplied_original != supplied_replacement
      raise ArgumentError, "original and replacement cannot be the same method"
    end

    def validate_no_mixing!
      return if positional.length <= 1
      return if @kw_original.nil? && @kw_replacement.nil?
      raise ArgumentError, "cannot mix positional and keyword original:/replacement:"
    end

    def validate_no_extra_positional!
      return if positional.length <= 3
      raise ArgumentError, "implemented_twice takes at most 3 positional arguments"
    end
  end
end

require_relative "both_is_good/context"
require_relative "both_is_good/version"
require_relative "both_is_good/comparators"
require_relative "both_is_good/configuration"
require_relative "both_is_good/local_configuration"
require_relative "both_is_good/invocation"
require_relative "both_is_good/implemented_twice"
