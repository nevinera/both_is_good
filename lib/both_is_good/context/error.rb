module BothIsGood
  module Context
    class Error
      include BothIsGood::Memoization
      include BothIsGood::Context::Names

      attr_reader :error, :args, :dispatched_name

      def initialize(target:, args:, error:, dispatched_name:)
        @target = target
        @args = args
        @error = error
        @dispatched_name = dispatched_name
      end

      def target_class = @target.target_class

      def method_name = @target.method_name

      memoize def target_class_name = target_class.name
      memoize def target_class_string = class_to_tag(target_class)
      memoize def tag = method_to_tag(target_class, method_name)
    end
  end
end
