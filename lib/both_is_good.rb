require_relative "both_is_good/memoization"

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

    def implemented_twice(*positional, primary: nil, secondary: nil, **opts)
      implementer = DualImplementer.new(*positional, target: self, primary:, secondary:, **opts)
      implementer.apply_aliases!
      runner = implementer.implementation

      define_method(implementer.name) do |*args, **kwargs|
        runner.call(self, *args, **kwargs)
      end
    end
  end

  class DualImplementer
    include Memoization

    def initialize(*positional, target:, primary:, secondary:, **opts)
      @target = target
      @positional = positional
      @kw_primary = primary
      @kw_secondary = secondary
      @opts = opts

      validate!
    end

    attr_reader :positional, :target, :opts

    memoize def name = positional.first
    memoize def primary = aliased_primary? ? :"_bothisgood_primary_#{name}" : original_primary
    memoize def secondary = aliased_secondary? ? :"_bothisgood_secondary_#{name}" : original_secondary

    def apply_aliases!
      target.alias_method(primary, name) if aliased_primary?
      target.alias_method(secondary, name) if aliased_secondary?
    end

    memoize def implementation = ImplementedTwice.new(target, primary:, secondary:, **opts)

    private

    memoize def original_primary = @kw_primary || positional[-2]
    memoize def original_secondary = @kw_secondary || positional.last

    memoize def aliased_primary? = original_primary == name
    memoize def aliased_secondary? = original_secondary == name

    def validate!
      validate_name_supplied!
      validate_secondary_supplied!
      validate_no_primary_secondary_match!
      validate_no_mixing!
      validate_no_extra_positional!
    end

    def validate_name_supplied!
      return unless positional.empty?
      raise(ArgumentError, "the 'name' positional parameter is required")
    end

    def validate_secondary_supplied!
      return if @kw_secondary || positional.length >= 2
      raise ArgumentError, "secondary is required, either as a positional argument or as a keyword argument"
    end

    def validate_no_primary_secondary_match!
      return if original_primary != original_secondary
      raise ArgumentError, "primary and secondary cannot be the same method"
    end

    def validate_no_mixing!
      return if positional.length <= 1
      return if @kw_primary.nil? && @kw_secondary.nil?
      raise ArgumentError, "cannot mix positional and keyword primary:/secondary:"
    end

    def validate_no_extra_positional!
      return if positional.length <= 3
      raise ArgumentError, "implemented_twice takes at most 3 positional arguments"
    end
  end
end

require_relative "both_is_good/version"
require_relative "both_is_good/configuration"
require_relative "both_is_good/local_configuration"
require_relative "both_is_good/invocation"
require_relative "both_is_good/implemented_twice"
