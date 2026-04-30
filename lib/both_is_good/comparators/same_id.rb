module BothIsGood
  module Comparators
    class SameId < Base
      def call = both_nil? || ids_match?

      private

      def both_nil? = a.nil? && b.nil?

      def neither_nil? = !a.nil? && !b.nil?

      def ids_match? = neither_nil? && a.public_send(:id) == b.public_send(:id)
    end
  end
end
