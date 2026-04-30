module BothIsGood
  module Comparators
  end
end

require_relative "comparators/base"
require_relative "comparators/floating_point"
require_relative "comparators/string_case_insensitive"
require_relative "comparators/same_id"

module BothIsGood
  module Comparators
    DEFAULT_COMPARATORS = {
      float: FloatingPoint,
      string_ci: StringCaseInsensitive,
      same_id: SameId
    }.freeze
  end
end
