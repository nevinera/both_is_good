module BothIsGood
  module Context
    class Result
      include BothIsGood::Memoization
      include BothIsGood::Context::Names

      attr_reader :args, :primary_result, :secondary_result

      def initialize(target:, args:, primary_result:, secondary_result:, names:)
        @target = target
        @args = args
        @primary_result = primary_result
        @secondary_result = secondary_result
        @names = names
      end

      memoize def target_class = @target.target_class

      memoize def method_name = @target.method_name

      memoize def primary_name = @names[:primary]

      memoize def secondary_name = @names[:secondary]

      memoize def target_class_name = target_class.name

      memoize def target_class_string = class_to_tag(target_class)

      memoize def tag = method_to_tag(target_class, method_name)
    end
  end
end
