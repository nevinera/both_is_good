RSpec.describe BothIsGood::Invocation do
  let(:owner_class) do
    Class.new do
      def primary_impl(*args, **kwargs) = :primary

      def secondary_impl(*args, **kwargs) = :secondary
    end
  end

  let(:target) { owner_class.new }
  let(:invocation_target) { BothIsGood::Target.new(target, :the_method, owner_class) }
  let(:config_opts) { {} }

  let(:local_config) do
    BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, **config_opts)
  end

  subject(:invocation) { described_class.new(local_config, invocation_target, [], {}) }

  it "returns the primary result" do
    expect(invocation.run).to eq(:primary)
  end

  it "calls secondary" do
    expect(target).to receive(:secondary_impl).and_call_original
    invocation.run
  end

  it "passes args to primary" do
    target.define_singleton_method(:primary_impl) { |*args, **kwargs| [:primary, args, kwargs] }
    expect(described_class.new(local_config, invocation_target, [1, 2], {x: 3}).run).to eq([:primary, [1, 2], {x: 3}])
  end

  it "passes args to secondary" do
    expect(target).to receive(:secondary_impl).with(1, 2, x: 3)
    described_class.new(local_config, invocation_target, [1, 2], {x: 3}).run
  end

  describe "rate" do
    context "with rate: 1.0" do
      it "always calls secondary" do
        expect(target).to receive(:secondary_impl).and_call_original
        invocation.run
      end
    end

    context "with rate: 0.0" do
      let(:config_opts) { {rate: 0.0} }

      it "never calls secondary" do
        expect(target).not_to receive(:secondary_impl)
        invocation.run
      end

      it "still returns the primary result" do
        expect(invocation.run).to eq(:primary)
      end
    end

    context "with a fractional rate" do
      let(:config_opts) { {rate: 0.5} }

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

  describe "switch" do
    context "when switch is nil" do
      it "returns the original result" do
        expect(invocation.run).to eq(:primary)
      end
    end

    context "when switch returns false" do
      let(:config_opts) { {switch: -> { false }} }

      it "returns the original result" do
        expect(invocation.run).to eq(:primary)
      end
    end

    context "when switch returns true" do
      let(:config_opts) { {switch: -> { true }} }

      it "returns the replacement result" do
        expect(invocation.run).to eq(:secondary)
      end

      it "still calls original at the given rate" do
        allow(invocation).to receive(:rand).and_return(0.0)
        expect(target).to receive(:primary_impl).and_call_original
        invocation.run
      end

      it "does not call original when rate gates it out" do
        allow(invocation).to receive(:rand).and_return(1.0)
        expect(target).not_to receive(:primary_impl)
        invocation.run
      end

      it "yields (replacement_result, original_result) to on_compare" do
        received = []
        hook = ->(ctx) { received << ctx }
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, switch: -> { true }, on_compare: hook)
        described_class.new(config, invocation_target, [], {}).run
        expect(received.map { [_1.primary_result, _1.secondary_result] }).to eq([[:secondary, :primary]])
      end
    end

    context "with arity-0 switch" do
      let(:switch) { -> { true } }
      let(:config_opts) { {switch: switch} }

      it "calls switch with no arguments" do
        expect(switch).to receive(:call).with(no_args).and_call_original
        invocation.run
      end
    end

    context "with arity-1 switch" do
      let(:switch) { ->(ctx) { false } }
      let(:config_opts) { {switch: switch} }

      it "calls switch with a Context::Switching object" do
        expect(switch).to receive(:call).with(an_instance_of(BothIsGood::Context::Switching)).and_call_original
        invocation.run
      end

      it "passes the correct target_class and method_name in the context" do
        received = []
        switch = ->(ctx) { (received << ctx) && false }
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, switch:)
        described_class.new(config, invocation_target, [], {}).run
        expect(received.map { [_1.target_class, _1.method_name] }).to eq([[owner_class, :the_method]])
      end
    end
  end

  describe "comparator" do
    let(:comparator) { ->(a, b) { a.even? == b.even? } }
    let(:config_opts) { {comparator: comparator} }

    let(:owner_class) do
      Class.new do
        def primary_impl(*args, **kwargs) = 2

        def secondary_impl(*args, **kwargs) = 3
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

    context "when comparator is a class" do
      let(:comparator_class) do
        Class.new do
          def initialize(a, b)
            @a = a
            @b = b
          end

          def call = @a.even? == @b.even?
        end
      end
      let(:config_opts) { {comparator: comparator_class} }

      it "instantiates the comparator with both results" do
        expect(comparator_class).to receive(:new).with(2, 3).and_call_original
        invocation.run
      end

      it "uses the return value of call to determine match" do
        log = []
        config = BothIsGood::LocalConfiguration.new(
          nil,
          owner: owner_class,
          original: :primary_impl,
          replacement: :secondary_impl,
          comparator: comparator_class,
          on_mismatch: ->(ctx) { log << :mismatch }
        )
        described_class.new(config, invocation_target, [], {}).run
        expect(log).to eq([:mismatch])
      end
    end
  end

  describe "on_compare" do
    it "is not called when secondary is skipped" do
      hook = ->(ctx) {}
      config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, rate: 0.0, on_compare: hook)
      expect(hook).not_to receive(:call)
      described_class.new(config, invocation_target, [], {}).run
    end

    context "with arity 1" do
      let(:hook) { ->(ctx) {} }
      let(:config_opts) { {on_compare: hook} }

      it "is called with a Context::Result" do
        expect(hook).to receive(:call).with(an_instance_of(BothIsGood::Context::Result))
        invocation.run
      end

      it "exposes primary and secondary results" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: ->(ctx) { received << ctx })
        described_class.new(config, invocation_target, [], {}).run
        expect(received.map { [_1.primary_result, _1.secondary_result] }).to eq([[:primary, :secondary]])
      end

      it "exposes call args" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: ->(ctx) { received << ctx })
        described_class.new(config, invocation_target, [1, 2], {}).run
        expect(received.map(&:args)).to eq([[1, 2]])
      end

      it "includes kwargs in args" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: ->(ctx) { received << ctx })
        described_class.new(config, invocation_target, [1], {x: 2}).run
        expect(received.map(&:args)).to eq([[1, {x: 2}]])
      end

      it "exposes primary and secondary names" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: ->(ctx) { received << ctx })
        described_class.new(config, invocation_target, [], {}).run
        expect(received.map { [_1.primary_name, _1.secondary_name] }).to eq([[:primary_impl, :secondary_impl]])
      end
    end
  end

  describe "on_mismatch" do
    it "is not called when secondary is skipped" do
      hook = ->(ctx) {}
      config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, rate: 0.0, on_mismatch: hook)
      expect(hook).not_to receive(:call)
      described_class.new(config, invocation_target, [], {}).run
    end

    it "is not called when results match" do
      hook = ->(ctx) {}
      matching_class = Class.new do
        def primary_impl(*args, **kwargs) = :same

        def secondary_impl(*args, **kwargs) = :same
      end
      config = BothIsGood::LocalConfiguration.new(nil, owner: matching_class, original: :primary_impl, replacement: :secondary_impl, on_mismatch: hook)
      expect(hook).not_to receive(:call)
      described_class.new(config, BothIsGood::Target.new(matching_class.new, :the_method, matching_class), [], {}).run
    end

    context "with arity 1" do
      let(:hook) { ->(ctx) {} }
      let(:config_opts) { {on_mismatch: hook} }

      it "is called with a Context::Result" do
        expect(hook).to receive(:call).with(an_instance_of(BothIsGood::Context::Result))
        invocation.run
      end

      it "exposes primary and secondary results" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_mismatch: ->(ctx) { received << ctx })
        described_class.new(config, invocation_target, [], {}).run
        expect(received.map { [_1.primary_result, _1.secondary_result] }).to eq([[:primary, :secondary]])
      end
    end
  end

  describe "on_primary_error" do
    let(:error) { RuntimeError.new("boom") }

    before do
      err = error
      target.define_singleton_method(:primary_impl) { |*args, **kwargs| raise err }
    end

    it "re-raises the primary error" do
      expect { invocation.run }.to raise_error(error)
    end

    it "does not call secondary" do
      expect(target).not_to receive(:secondary_impl)
      begin
        invocation.run
      rescue
        nil
      end
    end

    context "with arity 1" do
      let(:hook) { ->(ctx) {} }
      let(:config_opts) { {on_primary_error: hook} }

      it "is called with a Context::Error" do
        expect(hook).to receive(:call).with(an_instance_of(BothIsGood::Context::Error))
        begin
          invocation.run
        rescue
          nil
        end
      end

      it "exposes the error, args, and dispatched_name" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_primary_error: ->(ctx) { received << ctx })
        begin
          described_class.new(config, invocation_target, [1, 2], {}).run
        rescue
          nil
        end
        expect(received.map { [_1.error, _1.args, _1.dispatched_name] }).to eq([[error, [1, 2], :primary_impl]])
      end
    end
  end

  describe "on_secondary_error" do
    let(:error) { RuntimeError.new("boom") }

    let(:owner_class) do
      err = error
      Class.new do
        def primary_impl(*args, **kwargs) = :primary
        define_method(:secondary_impl) { |*args, **kwargs| raise err }
      end
    end

    it "swallows secondary errors even without a hook" do
      expect(invocation.run).to eq(:primary)
    end

    it "does not call result hooks when secondary raises" do
      hook = ->(ctx) {}
      config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: hook)
      expect(hook).not_to receive(:call)
      described_class.new(config, invocation_target, [], {}).run
    end

    context "with arity 1" do
      let(:hook) { ->(ctx) {} }
      let(:config_opts) { {on_secondary_error: hook} }

      it "is called with a Context::Error" do
        expect(hook).to receive(:call).with(an_instance_of(BothIsGood::Context::Error))
        invocation.run
      end

      it "exposes the error, args, and dispatched_name" do
        received = []
        config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_secondary_error: ->(ctx) { received << ctx })
        described_class.new(config, invocation_target, [1, 2], {}).run
        expect(received.map { [_1.error, _1.args, _1.dispatched_name] }).to eq([[error, [1, 2], :secondary_impl]])
      end
    end
  end

  describe "on_hook_error" do
    let(:hook_error) { RuntimeError.new("hook boom") }

    it "is called when a result hook raises" do
      on_hook_error = ->(e) {}
      bad_hook = ->(ctx) { raise hook_error }
      config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: bad_hook, on_hook_error: on_hook_error)
      expect(on_hook_error).to receive(:call).with(hook_error)
      described_class.new(config, invocation_target, [], {}).run
    end

    it "is called when an error hook raises" do
      err = RuntimeError.new("secondary boom")
      on_hook_error = ->(e) {}
      bad_hook = ->(e) { raise hook_error }
      raising_target = owner_class.new
      raising_target.define_singleton_method(:secondary_impl) { |*a, **kw| raise err }
      config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_secondary_error: bad_hook, on_hook_error: on_hook_error)
      expect(on_hook_error).to receive(:call).with(hook_error)
      described_class.new(config, BothIsGood::Target.new(raising_target, :the_method, owner_class), [], {}).run
    end

    it "re-raises hook errors when not set" do
      bad_hook = ->(ctx) { raise hook_error }
      config = BothIsGood::LocalConfiguration.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, on_compare: bad_hook)
      expect { described_class.new(config, invocation_target, [], {}).run }.to raise_error(hook_error)
    end
  end
end
