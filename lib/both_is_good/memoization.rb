module BothIsGood
  module Memoization
    def self.included(base) = base.extend(ClassMethods)

    module ClassMethods
      def memoize(method_name)
        original_method = instance_method(method_name)

        define_method(method_name) do |*args|
          raise ArgumentError, "Cannot memoize methods that take arguments" if args.any?

          @memo ||= {}

          if @memo.key?(method_name)
            @memo[method_name]
          else
            @memo[method_name] = original_method.bind_call(self)
          end
        end
      end
    end
  end
end
