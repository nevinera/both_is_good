module BothIsGood
  module Comparators
    class FloatingPoint < Base
      def call = a == b || within_epsilon?

      private

      def local_epsilon = Float::EPSILON * [1.0, a.abs, b.abs].max

      def within_epsilon? = a.finite? && b.finite? && (a - b).abs <= local_epsilon
    end
  end
end
