RSpec.describe BothIsGood::Invocation do
  let(:target) do
    Object.new.tap do |obj|
      obj.define_singleton_method(:primary_impl) { |*args, **kwargs| :primary }
      obj.define_singleton_method(:secondary_impl) { |*args, **kwargs| :secondary }
    end
  end

  let(:config) do
    {primary: :primary_impl, secondary: :secondary_impl, rate: 1.0,
     comparator: nil, on_compare: nil, on_mismatch: nil, on_secondary_error: nil}
  end

  subject(:invocation) { described_class.new(config, target, [], {}) }

  it "returns the primary result" do
    expect(invocation.run).to eq(:primary)
  end

  it "calls secondary" do
    expect(target).to receive(:secondary_impl).and_call_original
    invocation.run
  end

  it "passes args to primary" do
    target.define_singleton_method(:primary_impl) { |*args, **kwargs| [:primary, args, kwargs] }
    expect(described_class.new(config, target, [1, 2], {x: 3}).run).to eq([:primary, [1, 2], {x: 3}])
  end

  it "passes args to secondary" do
    expect(target).to receive(:secondary_impl).with(1, 2, x: 3)
    described_class.new(config, target, [1, 2], {x: 3}).run
  end

  describe "rate" do
    context "with rate: 1.0" do
      it "always calls secondary" do
        expect(target).to receive(:secondary_impl).and_call_original
        invocation.run
      end
    end

    context "with rate: 0.0" do
      let(:config) { super().merge(rate: 0.0) }

      it "never calls secondary" do
        expect(target).not_to receive(:secondary_impl)
        invocation.run
      end

      it "still returns the primary result" do
        expect(invocation.run).to eq(:primary)
      end
    end

    context "with a fractional rate" do
      let(:config) { super().merge(rate: 0.5) }

      it "calls secondary when rand is below the rate" do
        allow(invocation).to receive(:rand).and_return(0.49)
        expect(target).to receive(:secondary_impl).and_call_original
        invocation.run
      end

      it "skips secondary when rand is at or above the rate" do
        allow(invocation).to receive(:rand).and_return(0.5)
        expect(target).not_to receive(:secondary_impl)
        invocation.run
      end
    end
  end

  describe "comparator" do
    let(:comparator) { ->(a, b) { a.even? == b.even? } }
    let(:config) { super().merge(comparator: comparator) }

    let(:target) do
      Object.new.tap do |obj|
        obj.define_singleton_method(:primary_impl) { |*args, **kwargs| 2 }
        obj.define_singleton_method(:secondary_impl) { |*args, **kwargs| 3 }
      end
    end

    it "calls the comparator with the primary and secondary results" do
      expect(comparator).to receive(:call).with(2, 3).and_call_original
      invocation.run
    end

    it "does not call the comparator when secondary is skipped" do
      allow(invocation).to receive(:rand).and_return(1.0)
      expect(comparator).not_to receive(:call)
      invocation.run
    end
  end

  describe "on_compare" do
    let(:names) { {primary: :primary_impl, secondary: :secondary_impl} }

    it "is not called when secondary is skipped" do
      hook = ->(a, b) {}
      invocation = described_class.new(config.merge(rate: 0.0, on_compare: hook), target, [], {})
      expect(hook).not_to receive(:call)
      invocation.run
    end

    context "with arity 2" do
      let(:config) { super().merge(on_compare: ->(a, b) {}) }

      it "is called with the primary and secondary results" do
        expect(config[:on_compare]).to receive(:call).with(:primary, :secondary)
        invocation.run
      end
    end

    context "with arity 3" do
      let(:config) { super().merge(on_compare: ->(a, b, n) {}) }

      it "is called with the results and names hash" do
        expect(config[:on_compare]).to receive(:call).with(:primary, :secondary, names)
        invocation.run
      end
    end

    context "with arity 4" do
      let(:config) { super().merge(on_compare: ->(a, b, ca, n) {}) }

      it "is called with the results, call_args, and names hash" do
        expect(config[:on_compare]).to receive(:call).with(:primary, :secondary, [1, 2], names)
        described_class.new(config, target, [1, 2], {}).run
      end

      it "includes kwargs in call_args" do
        expect(config[:on_compare]).to receive(:call).with(:primary, :secondary, [1, {x: 2}], names)
        described_class.new(config, target, [1], {x: 2}).run
      end
    end
  end

  describe "on_mismatch" do
    let(:names) { {primary: :primary_impl, secondary: :secondary_impl} }

    it "is not called when secondary is skipped" do
      hook = ->(a, b) {}
      invocation = described_class.new(config.merge(rate: 0.0, on_mismatch: hook), target, [], {})
      expect(hook).not_to receive(:call)
      invocation.run
    end

    it "is not called when results match" do
      hook = ->(a, b) {}
      matching_target = Object.new.tap do |obj|
        obj.define_singleton_method(:primary_impl) { |*args, **kwargs| :same }
        obj.define_singleton_method(:secondary_impl) { |*args, **kwargs| :same }
      end
      invocation = described_class.new(config.merge(on_mismatch: hook), matching_target, [], {})
      expect(hook).not_to receive(:call)
      invocation.run
    end

    context "with arity 2" do
      let(:config) { super().merge(on_mismatch: ->(a, b) {}) }

      it "is called with the primary and secondary results" do
        expect(config[:on_mismatch]).to receive(:call).with(:primary, :secondary)
        invocation.run
      end
    end

    context "with arity 3" do
      let(:config) { super().merge(on_mismatch: ->(a, b, n) {}) }

      it "is called with the results and names hash" do
        expect(config[:on_mismatch]).to receive(:call).with(:primary, :secondary, names)
        invocation.run
      end
    end

    context "with arity 4" do
      let(:config) { super().merge(on_mismatch: ->(a, b, ca, n) {}) }

      it "is called with the results, call_args, and names hash" do
        expect(config[:on_mismatch]).to receive(:call).with(:primary, :secondary, [1, 2], names)
        described_class.new(config, target, [1, 2], {}).run
      end
    end
  end

  describe "on_secondary_error" do
    let(:error) { RuntimeError.new("boom") }

    let(:raising_target) do
      err = error
      Object.new.tap do |obj|
        obj.define_singleton_method(:primary_impl) { |*args, **kwargs| :primary }
        obj.define_singleton_method(:secondary_impl) { |*args, **kwargs| raise err }
      end
    end

    subject(:invocation) { described_class.new(config, raising_target, [], {}) }

    it "swallows secondary errors even without a hook" do
      expect(invocation.run).to eq(:primary)
    end

    it "does not call result hooks when secondary raises" do
      hook = ->(a, b) {}
      invocation = described_class.new(config.merge(on_compare: hook), raising_target, [], {})
      expect(hook).not_to receive(:call)
      invocation.run
    end

    context "with arity 1" do
      let(:config) { super().merge(on_secondary_error: ->(e) {}) }

      it "is called with the error" do
        expect(config[:on_secondary_error]).to receive(:call).with(error)
        invocation.run
      end
    end

    context "with arity 2" do
      let(:config) { super().merge(on_secondary_error: ->(e, ca) {}) }

      it "is called with the error and call_args" do
        expect(config[:on_secondary_error]).to receive(:call).with(error, [1, 2])
        described_class.new(config, raising_target, [1, 2], {}).run
      end
    end

    context "with arity 3" do
      let(:config) { super().merge(on_secondary_error: ->(e, ca, n) {}) }

      it "is called with the error, call_args, and secondary method name" do
        expect(config[:on_secondary_error]).to receive(:call).with(error, [1, 2], :secondary_impl)
        described_class.new(config, raising_target, [1, 2], {}).run
      end
    end
  end
end
