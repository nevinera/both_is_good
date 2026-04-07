module NamesSpecFixtures
  module OuterModule
    class InnerClass; end
  end

  class SimpleClass; end

  class HTMLParser; end
end

RSpec.describe BothIsGood::Context::Names do
  subject(:obj) { Object.new.tap { |o| o.extend(described_class) } }

  describe "#underscore" do
    it "lowercases a simple CamelCase name" do
      expect(obj.underscore("SimpleClass")).to eq("simple_class")
    end

    it "replaces :: with /" do
      expect(obj.underscore("Outer::Inner")).to eq("outer/inner")
    end

    it "handles multiple namespace levels" do
      expect(obj.underscore("NamesSpecFixtures::OuterModule::InnerClass")).to eq("names_spec_fixtures/outer_module/inner_class")
    end

    it "handles acronyms followed by lowercase" do
      expect(obj.underscore("HTMLParser")).to eq("html_parser")
    end
  end

  describe "#class_to_tag" do
    it "returns the underscored class name" do
      expect(obj.class_to_tag(NamesSpecFixtures::SimpleClass)).to eq("names_spec_fixtures/simple_class")
    end

    it "handles namespaced classes" do
      expect(obj.class_to_tag(NamesSpecFixtures::OuterModule::InnerClass)).to eq("names_spec_fixtures/outer_module/inner_class")
    end
  end

  describe "#method_to_tag" do
    it "combines the class tag and method name with --" do
      expect(obj.method_to_tag(NamesSpecFixtures::SimpleClass, :my_method)).to eq("names_spec_fixtures/simple_class--my_method")
    end
  end
end
