module BothIsGood
  module Context
    class Switching
      include BothIsGood::Memoization
      include BothIsGood::Context::Names

      def initialize(target_class, method_name)
        @target_class = target_class
        @method_name = method_name
      end

      attr_reader :target_class, :method_name

      memoize def target_class_name = target_class.name

      memoize def target_class_string = class_to_tag(target_class)

      memoize def tag = method_to_tag(target_class, method_name)
    end
  end
end
