module BothIsGood
  module Comparators
    class StringCaseInsensitive < Base
      def call = a == b || a.downcase == b.downcase
    end
  end
end
