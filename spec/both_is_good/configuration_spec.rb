RSpec.describe BothIsGood::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults rate to 1.0" do
      expect(config.rate).to eq(1.0)
    end

    it "defaults switch to nil" do
      expect(config.switch).to be_nil
    end

    it "defaults all hooks to nil" do
      expect(config.on_mismatch).to be_nil
      expect(config.on_compare).to be_nil
      expect(config.on_primary_error).to be_nil
      expect(config.on_secondary_error).to be_nil
      expect(config.on_hook_error).to be_nil
    end
  end

  describe "initialization from a base config" do
    let(:base) do
      described_class.new.tap do |c|
        c.rate = 0.5
        c.on_hook_error = ->(e) { e }
      end
    end

    subject(:config) { described_class.new(base) }

    it "copies rate from the base" do
      expect(config.rate).to eq(0.5)
    end

    it "copies hooks from the base" do
      expect(config.on_hook_error).to eq(base.on_hook_error)
    end

    it "leaves unset hooks as nil" do
      expect(config.on_mismatch).to be_nil
    end
  end

  describe "initialization with overrides" do
    subject(:config) { described_class.new(nil, rate: 0.25) }

    it "applies the override" do
      expect(config.rate).to eq(0.25)
    end
  end

  describe "initialization with base and overrides" do
    let(:base) do
      described_class.new.tap { |c| c.rate = 0.5 }
    end

    subject(:config) { described_class.new(base, rate: 0.1) }

    it "overrides take precedence over the base" do
      expect(config.rate).to eq(0.1)
    end
  end

  describe "#dup" do
    before { config.rate = 0.3 }

    subject(:duped) { config.dup }

    it "returns a new Configuration" do
      expect(duped).not_to be(config)
    end

    it "copies the values" do
      expect(duped.rate).to eq(0.3)
    end

    it "changes to the dup do not affect the original" do
      duped.rate = 0.7
      expect(config.rate).to eq(0.3)
    end
  end

  describe "#rate=" do
    it "accepts values between 0.0 and 1.0" do
      expect { config.rate = 0.0 }.not_to raise_error
      expect { config.rate = 1.0 }.not_to raise_error
      expect { config.rate = 0.5 }.not_to raise_error
    end

    it "rejects values outside 0.0..1.0" do
      expect { config.rate = -0.1 }.to raise_error(ArgumentError)
      expect { config.rate = 1.1 }.to raise_error(ArgumentError)
    end

    it "rejects non-numeric values" do
      expect { config.rate = "0.5" }.to raise_error(ArgumentError)
    end
  end

  describe "#switch=" do
    it "accepts nil" do
      expect { config.switch = nil }.not_to raise_error
    end

    it "accepts callables with arity 0 or 2" do
      expect { config.switch = -> {} }.not_to raise_error
      expect { config.switch = ->(ctx) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.switch = ->(a, b) {} }.to raise_error(ArgumentError)
      expect { config.switch = ->(a, b, c) {} }.to raise_error(ArgumentError)
    end

    it "rejects non-callables" do
      expect { config.switch = "always" }.to raise_error(ArgumentError)
    end
  end

  describe "#on_mismatch=" do
    it "accepts nil" do
      expect { config.on_mismatch = nil }.not_to raise_error
    end

    it "accepts callables with arity 1" do
      expect { config.on_mismatch = ->(ctx) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_mismatch = ->(a, b) {} }.to raise_error(ArgumentError)
      expect { config.on_mismatch = -> {} }.to raise_error(ArgumentError)
    end

    it "rejects non-callables" do
      expect { config.on_mismatch = "handler" }.to raise_error(ArgumentError)
    end
  end

  describe "#on_compare=" do
    it "accepts nil" do
      expect { config.on_compare = nil }.not_to raise_error
    end

    it "accepts callables with arity 1" do
      expect { config.on_compare = ->(ctx) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_compare = ->(a, b) {} }.to raise_error(ArgumentError)
      expect { config.on_compare = -> {} }.to raise_error(ArgumentError)
    end
  end

  describe "#on_primary_error=" do
    it "accepts nil" do
      expect { config.on_primary_error = nil }.not_to raise_error
    end

    it "accepts callables with arity 1" do
      expect { config.on_primary_error = ->(ctx) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_primary_error = ->(a, b) {} }.to raise_error(ArgumentError)
      expect { config.on_primary_error = -> {} }.to raise_error(ArgumentError)
    end
  end

  describe "#on_secondary_error=" do
    it "accepts nil" do
      expect { config.on_secondary_error = nil }.not_to raise_error
    end

    it "accepts callables with arity 1" do
      expect { config.on_secondary_error = ->(ctx) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_secondary_error = ->(a, b) {} }.to raise_error(ArgumentError)
      expect { config.on_secondary_error = -> {} }.to raise_error(ArgumentError)
    end
  end

  describe "#on_hook_error=" do
    it "accepts nil" do
      expect { config.on_hook_error = nil }.not_to raise_error
    end

    it "accepts a callable with arity 1" do
      expect { config.on_hook_error = ->(e) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_hook_error = ->(a, b) {} }.to raise_error(ArgumentError)
      expect { config.on_hook_error = -> {} }.to raise_error(ArgumentError)
    end
  end

  describe "#comparators" do
    it "initializes with the default comparators when given no base" do
      expect(described_class.new(nil).comparators).to eq(BothIsGood::Comparators::DEFAULT_COMPARATORS)
    end

    it "is inherited from a base config" do
      klass = Class.new do
        def initialize(a, b) = nil

        def call = true
      end
      base = described_class.new(nil)
      base.register_comparator(:my_comparator, klass)
      expect(described_class.new(base).comparators).to include(my_comparator: klass)
    end

    it "does not share state with the base config" do
      base = described_class.new(nil)
      derived = described_class.new(base)
      klass = Class.new do
        def initialize(a, b) = nil

        def call = true
      end
      derived.register_comparator(:my_comparator, klass)
      expect(base.comparators).not_to include(my_comparator: klass)
    end
  end

  describe "#register_comparator" do
    let(:comparator_class) do
      Class.new do
        def initialize(a, b) = nil

        def call = true
      end
    end

    it "stores the comparator class by name" do
      config.register_comparator(:my_comparator, comparator_class)
      expect(config.comparators[:my_comparator]).to be(comparator_class)
    end

    it "raises when name is not a Symbol" do
      expect { config.register_comparator("my_comparator", comparator_class) }
        .to raise_error(ArgumentError, /Symbol/)
    end

    it "raises when klass is not a class" do
      expect { config.register_comparator(:my_comparator, -> {}) }
        .to raise_error(ArgumentError, /class/)
    end

    it "raises when call is not defined" do
      klass = Class.new { def initialize(a, b) = nil }
      expect { config.register_comparator(:my_comparator, klass) }
        .to raise_error(ArgumentError, /call/)
    end

    it "raises when call has wrong arity" do
      klass = Class.new do
        def initialize(a, b) = nil

        def call(x) = nil
      end
      expect { config.register_comparator(:my_comparator, klass) }
        .to raise_error(ArgumentError, /call/)
    end

    it "raises when initialize has wrong arity" do
      klass = Class.new do
        def initialize(a) = nil

        def call = true
      end
      expect { config.register_comparator(:my_comparator, klass) }
        .to raise_error(ArgumentError, /initialize/)
    end
  end

  describe "inheriting from global configuration" do
    let(:mock_global) { described_class.new(nil).tap { |c| c.rate = 0.25 } }

    before { allow(described_class).to receive(:global).and_return(mock_global) }

    it "inherits attributes from the global config" do
      expect(described_class.new.rate).to eq(0.25)
    end

    it "can override inherited attributes" do
      expect(described_class.new(nil, rate: 0.75).rate).to eq(0.75)
    end
  end
end
