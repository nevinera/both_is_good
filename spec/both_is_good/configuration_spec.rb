RSpec.describe BothIsGood::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults rate to 1.0" do
      expect(config.rate).to eq(1.0)
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

  describe "#on_mismatch=" do
    it "accepts nil" do
      expect { config.on_mismatch = nil }.not_to raise_error
    end

    it "accepts callables with arity 2, 3, or 4" do
      expect { config.on_mismatch = ->(a, b) {} }.not_to raise_error
      expect { config.on_mismatch = ->(a, b, c) {} }.not_to raise_error
      expect { config.on_mismatch = ->(a, b, c, d) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_mismatch = ->(a) {} }.to raise_error(ArgumentError)
      expect { config.on_mismatch = ->(a, b, c, d, e) {} }.to raise_error(ArgumentError)
    end

    it "rejects non-callables" do
      expect { config.on_mismatch = "handler" }.to raise_error(ArgumentError)
    end
  end

  describe "#on_compare=" do
    it "accepts nil" do
      expect { config.on_compare = nil }.not_to raise_error
    end

    it "accepts callables with arity 2, 3, or 4" do
      expect { config.on_compare = ->(a, b) {} }.not_to raise_error
      expect { config.on_compare = ->(a, b, c) {} }.not_to raise_error
      expect { config.on_compare = ->(a, b, c, d) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_compare = ->(a) {} }.to raise_error(ArgumentError)
    end
  end

  describe "#on_primary_error=" do
    it "accepts nil" do
      expect { config.on_primary_error = nil }.not_to raise_error
    end

    it "accepts callables with arity 1, 2, or 3" do
      expect { config.on_primary_error = ->(a) {} }.not_to raise_error
      expect { config.on_primary_error = ->(a, b) {} }.not_to raise_error
      expect { config.on_primary_error = ->(a, b, c) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_primary_error = ->(a, b, c, d) {} }.to raise_error(ArgumentError)
    end
  end

  describe "#on_secondary_error=" do
    it "accepts nil" do
      expect { config.on_secondary_error = nil }.not_to raise_error
    end

    it "accepts callables with arity 1, 2, or 3" do
      expect { config.on_secondary_error = ->(a) {} }.not_to raise_error
      expect { config.on_secondary_error = ->(a, b) {} }.not_to raise_error
      expect { config.on_secondary_error = ->(a, b, c) {} }.not_to raise_error
    end

    it "rejects callables with other arities" do
      expect { config.on_secondary_error = ->(a, b, c, d) {} }.to raise_error(ArgumentError)
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
