module SwitchingSpecFixtures
  module OuterModule
    class InnerClass; end
  end

  class SimpleClass; end
end

RSpec.describe BothIsGood::Context::Switching do
  let(:method_name) { :my_method }

  subject(:ctx) { described_class.new(klass, method_name) }

  describe "#target_class" do
    let(:klass) { SwitchingSpecFixtures::SimpleClass }

    it "returns the class" do
      expect(ctx.target_class).to eq(klass)
    end
  end

  describe "#method_name" do
    let(:klass) { SwitchingSpecFixtures::SimpleClass }

    it "returns the method name" do
      expect(ctx.method_name).to eq(:my_method)
    end
  end

  describe "#target_class_name" do
    let(:klass) { SwitchingSpecFixtures::SimpleClass }

    it "returns the class name string" do
      expect(ctx.target_class_name).to eq("SwitchingSpecFixtures::SimpleClass")
    end
  end

  describe "#target_class_string" do
    context "with a simple class" do
      let(:klass) { SwitchingSpecFixtures::SimpleClass }

      it "returns the underscored class name" do
        expect(ctx.target_class_string).to eq("switching_spec_fixtures/simple_class")
      end
    end

    context "with a namespaced class" do
      let(:klass) { SwitchingSpecFixtures::OuterModule::InnerClass }

      it "uses slashes for namespace separators" do
        expect(ctx.target_class_string).to eq("switching_spec_fixtures/outer_module/inner_class")
      end
    end
  end

  describe "#tag" do
    let(:klass) { SwitchingSpecFixtures::SimpleClass }

    it "combines target_class_string and method_name with --" do
      expect(ctx.tag).to eq("switching_spec_fixtures/simple_class--my_method")
    end
  end
end
