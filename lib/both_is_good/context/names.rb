module BothIsGood
  module Context
    module Names
      def underscore(supplied_name)
        supplied_name
          .gsub("::", "/")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
      end

      def class_to_tag(klass) = underscore(klass.name)

      def method_to_tag(klass, method_name) = "#{class_to_tag(klass)}--#{method_name}"
    end
  end
end
