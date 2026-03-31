RSpec.describe BothIsGood::ClassMethods do
  let(:including_class) do
    Class.new do
      include BothIsGood

      def primary_impl(*args, **kwargs) = [:primary, args, kwargs]

      def secondary_impl(*args, **kwargs) = [:secondary, args, kwargs]

      implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl
    end
  end

  subject(:instance) { including_class.new }

  describe "#implemented_twice" do
    it "defines the named method" do
      expect(instance).to respond_to(:the_method)
    end

    it "returns the primary result" do
      expect(instance.the_method).to eq([:primary, [], {}])
    end

    it "calls secondary" do
      expect(instance).to receive(:secondary_impl).and_call_original
      instance.the_method
    end

    it "passes args to primary" do
      expect(instance.the_method(1, 2)).to eq([:primary, [1, 2], {}])
    end

    it "passes args to secondary" do
      expect(instance).to receive(:secondary_impl).with(1, 2)
      instance.the_method(1, 2)
    end

    it "passes kwargs to primary" do
      expect(instance.the_method(x: 1)).to eq([:primary, [], {x: 1}])
    end

    it "passes kwargs to secondary" do
      expect(instance).to receive(:secondary_impl).with(x: 1)
      instance.the_method(x: 1)
    end

    context "when name matches primary" do
      let(:including_class) do
        Class.new do
          include BothIsGood

          def the_method = :original

          def secondary_impl = :secondary

          implemented_twice :the_method, primary: :the_method, secondary: :secondary_impl
        end
      end

      it "aliases the original method out of the way" do
        expect(instance).to respond_to(:_bothisgood_primary_the_method)
      end

      it "returns the primary result" do
        expect(instance.the_method).to eq(:original)
      end
    end

    context "when name matches secondary" do
      let(:including_class) do
        Class.new do
          include BothIsGood

          def primary_impl = :primary

          def the_method = :original

          implemented_twice :the_method, primary: :primary_impl, secondary: :the_method
        end
      end

      it "aliases the original method out of the way" do
        expect(instance).to respond_to(:_bothisgood_secondary_the_method)
      end

      it "still calls the original secondary" do
        expect(instance).to receive(:_bothisgood_secondary_the_method).and_call_original
        instance.the_method
      end
    end
  end
end
