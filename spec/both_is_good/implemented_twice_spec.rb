RSpec.describe BothIsGood::ImplementedTwice do
  let(:target) do
    Object.new.tap do |obj|
      obj.define_singleton_method(:primary_impl) { |*args, **kwargs| :primary }
      obj.define_singleton_method(:secondary_impl) { |*args, **kwargs| :secondary }
    end
  end

  let(:runner) do
    described_class.new(primary: :primary_impl, secondary: :secondary_impl)
  end

  it "returns the primary result" do
    expect(runner.call(target)).to eq(:primary)
  end

  it "calls secondary" do
    expect(target).to receive(:secondary_impl).and_call_original
    runner.call(target)
  end

  it "passes args to primary" do
    target.define_singleton_method(:primary_impl) { |*args, **kwargs| [:primary, args, kwargs] }
    expect(runner.call(target, 1, 2, x: 3)).to eq([:primary, [1, 2], {x: 3}])
  end

  it "passes args to secondary" do
    expect(target).to receive(:secondary_impl).with(1, 2, x: 3)
    runner.call(target, 1, 2, x: 3)
  end

  describe "rate" do
    context "with rate: 1.0" do
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, rate: 1.0) }

      it "always calls secondary" do
        expect(target).to receive(:secondary_impl).and_call_original
        runner.call(target)
      end
    end

    context "with rate: 0.0" do
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, rate: 0.0) }

      it "never calls secondary" do
        expect(target).not_to receive(:secondary_impl)
        runner.call(target)
      end

      it "still returns the primary result" do
        expect(runner.call(target)).to eq(:primary)
      end
    end

    context "with a fractional rate" do
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, rate: 0.5) }

      it "calls secondary when rand is below the rate" do
        allow(runner).to receive(:rand).and_return(0.49)
        expect(target).to receive(:secondary_impl).and_call_original
        runner.call(target)
      end

      it "skips secondary when rand is at or above the rate" do
        allow(runner).to receive(:rand).and_return(0.5)
        expect(target).not_to receive(:secondary_impl)
        runner.call(target)
      end
    end
  end

  describe "comparator" do
    let(:comparator) { ->(a, b) { a.even? == b.even? } }

    let(:target) do
      Object.new.tap do |obj|
        obj.define_singleton_method(:primary_impl) { 2 }
        obj.define_singleton_method(:secondary_impl) { 3 }
      end
    end

    let(:runner) do
      described_class.new(primary: :primary_impl, secondary: :secondary_impl, comparator: comparator)
    end

    it "calls the comparator with the primary and secondary results" do
      expect(comparator).to receive(:call).with(2, 3).and_call_original
      runner.call(target)
    end

    it "does not call the comparator when secondary is skipped" do
      allow(runner).to receive(:rand).and_return(1.0)
      expect(comparator).not_to receive(:call)
      runner.call(target)
    end
  end

  describe "on_compare" do
    let(:names) { {primary: :primary_impl, secondary: :secondary_impl} }

    it "raises when supplied with an unsupported arity" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: ->(a) {})
      }.to raise_error(ArgumentError)
    end

    it "is not called when secondary is skipped" do
      hook = ->(a, b) {}
      runner = described_class.new(primary: :primary_impl, secondary: :secondary_impl, rate: 0.0, on_compare: hook)
      expect(hook).not_to receive(:call)
      runner.call(target)
    end

    context "with arity 2" do
      let(:hook) { ->(a, b) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: hook) }

      it "is called with the primary and secondary results" do
        expect(hook).to receive(:call).with(:primary, :secondary)
        runner.call(target)
      end
    end

    context "with arity 3" do
      let(:hook) { ->(a, b, n) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: hook) }

      it "is called with the results and names hash" do
        expect(hook).to receive(:call).with(:primary, :secondary, names)
        runner.call(target)
      end
    end

    context "with arity 4" do
      let(:hook) { ->(a, b, call_args, n) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: hook) }

      it "is called with the results, call_args, and names hash" do
        expect(hook).to receive(:call).with(:primary, :secondary, [1, 2], names)
        runner.call(target, 1, 2)
      end

      it "includes kwargs in call_args" do
        expect(hook).to receive(:call).with(:primary, :secondary, [1, {x: 2}], names)
        runner.call(target, 1, x: 2)
      end
    end
  end

  describe "on_mismatch" do
    let(:names) { {primary: :primary_impl, secondary: :secondary_impl} }

    it "raises when supplied with an unsupported arity" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: ->(a) {})
      }.to raise_error(ArgumentError)
    end

    it "is not called when secondary is skipped" do
      hook = ->(a, b) {}
      runner = described_class.new(primary: :primary_impl, secondary: :secondary_impl, rate: 0.0, on_mismatch: hook)
      expect(hook).not_to receive(:call)
      runner.call(target)
    end

    it "is not called when results match" do
      hook = ->(a, b) {}
      matching_target = Object.new.tap do |obj|
        obj.define_singleton_method(:primary_impl) { |*args, **kwargs| :same }
        obj.define_singleton_method(:secondary_impl) { |*args, **kwargs| :same }
      end
      runner = described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: hook)
      expect(hook).not_to receive(:call)
      runner.call(matching_target)
    end

    context "with arity 2" do
      let(:hook) { ->(a, b) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: hook) }

      it "is called with the primary and secondary results" do
        expect(hook).to receive(:call).with(:primary, :secondary)
        runner.call(target)
      end
    end

    context "with arity 3" do
      let(:hook) { ->(a, b, n) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: hook) }

      it "is called with the results and names hash" do
        expect(hook).to receive(:call).with(:primary, :secondary, names)
        runner.call(target)
      end
    end

    context "with arity 4" do
      let(:hook) { ->(a, b, call_args, n) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: hook) }

      it "is called with the results, call_args, and names hash" do
        expect(hook).to receive(:call).with(:primary, :secondary, [1, 2], names)
        runner.call(target, 1, 2)
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

    it "raises when supplied with an unsupported arity" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: ->(a, b, c, d) {})
      }.to raise_error(ArgumentError)
    end

    it "swallows secondary errors even without a hook" do
      runner = described_class.new(primary: :primary_impl, secondary: :secondary_impl)
      expect(runner.call(raising_target)).to eq(:primary)
    end

    it "does not call result hooks when secondary raises" do
      hook = ->(a, b) {}
      runner = described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: hook)
      expect(hook).not_to receive(:call)
      runner.call(raising_target)
    end

    context "with arity 1" do
      let(:hook) { ->(e) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: hook) }

      it "is called with the error" do
        expect(hook).to receive(:call).with(error)
        runner.call(raising_target)
      end
    end

    context "with arity 2" do
      let(:hook) { ->(e, call_args) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: hook) }

      it "is called with the error and call_args" do
        expect(hook).to receive(:call).with(error, [1, 2])
        runner.call(raising_target, 1, 2)
      end
    end

    context "with arity 3" do
      let(:hook) { ->(e, call_args, name) {} }
      let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: hook) }

      it "is called with the error, call_args, and secondary method name" do
        expect(hook).to receive(:call).with(error, [1, 2], :secondary_impl)
        runner.call(raising_target, 1, 2)
      end
    end
  end
end
