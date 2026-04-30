module BothIsGood
  module Comparators
    class Base
      def initialize(a, b)
        @a = a
        @b = b
      end

      private

      attr_reader :a, :b
    end
  end
end
