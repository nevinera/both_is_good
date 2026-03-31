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

    context "with rate: 1.0" do
      let(:including_class) do
        Class.new do
          include BothIsGood

          def primary_impl = :primary

          def secondary_impl = :secondary

          implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl, rate: 1.0
        end
      end

      it "always calls secondary" do
        expect(instance).to receive(:secondary_impl).and_call_original
        instance.the_method
      end
    end

    context "with rate: 0.0" do
      let(:including_class) do
        Class.new do
          include BothIsGood

          def primary_impl = :primary

          def secondary_impl = :secondary

          implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl, rate: 0.0
        end
      end

      it "never calls secondary" do
        expect(instance).not_to receive(:secondary_impl)
        instance.the_method
      end

      it "still returns the primary result" do
        expect(instance.the_method).to eq(:primary)
      end
    end

    context "with a fractional rate" do
      let(:including_class) do
        Class.new do
          include BothIsGood

          def primary_impl = :primary

          def secondary_impl = :secondary

          implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl, rate: 0.5
        end
      end

      it "calls secondary when rand is below the rate" do
        allow(instance).to receive(:rand).and_return(0.49)
        expect(instance).to receive(:secondary_impl).and_call_original
        instance.the_method
      end

      it "skips secondary when rand is above the rate" do
        allow(instance).to receive(:rand).and_return(0.5)
        expect(instance).not_to receive(:secondary_impl)
        instance.the_method
      end
    end

    context "with a comparator" do
      let(:comparator) { ->(a, b) { a.even? == b.even? } }

      let(:including_class) do
        comp = comparator
        Class.new do
          include BothIsGood

          def primary_impl = 2

          def secondary_impl = 3

          implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl, comparator: comp
        end
      end

      it "calls the comparator with the primary and secondary results" do
        expect(comparator).to receive(:call).with(2, 3).and_call_original
        instance.the_method
      end

      it "does not call the comparator when secondary is skipped" do
        allow(instance).to receive(:rand).and_return(1.0)
        expect(comparator).not_to receive(:call)
        instance.the_method
      end
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
