RSpec.describe BothIsGood::LocalConfiguration do
  let(:owner_class) do
    Class.new do
      def primary_impl = :primary

      def secondary_impl = :secondary
    end
  end

  subject(:local_config) do
    described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: :secondary_impl)
  end

  it "is a Configuration" do
    expect(local_config).to be_a(BothIsGood::Configuration)
  end

  it "exposes primary" do
    expect(local_config.primary).to eq(:primary_impl)
  end

  it "exposes secondary" do
    expect(local_config.secondary).to eq(:secondary_impl)
  end

  describe "primary validation" do
    it "raises when primary is nil" do
      expect { described_class.new(nil, owner: owner_class, primary: nil, secondary: :secondary_impl) }
        .to raise_error(ArgumentError)
    end

    it "raises when primary method is not defined on owner" do
      expect { described_class.new(nil, owner: owner_class, primary: :nonexistent, secondary: :secondary_impl) }
        .to raise_error(ArgumentError)
    end
  end

  describe "secondary validation" do
    it "raises when secondary is nil" do
      expect { described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: nil) }
        .to raise_error(ArgumentError)
    end

    it "raises when secondary method is not defined on owner" do
      expect { described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: :nonexistent) }
        .to raise_error(ArgumentError)
    end
  end

  describe "comparator validation" do
    it "accepts nil" do
      expect { described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: :secondary_impl, comparator: nil) }
        .not_to raise_error
    end

    it "accepts a callable with arity 2" do
      expect { described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: :secondary_impl, comparator: ->(a, b) {}) }
        .not_to raise_error
    end

    it "raises when comparator has wrong arity" do
      expect { described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: :secondary_impl, comparator: ->(a) {}) }
        .to raise_error(ArgumentError)
    end

    it "raises when comparator is not callable" do
      expect { described_class.new(nil, owner: owner_class, primary: :primary_impl, secondary: :secondary_impl, comparator: "not callable") }
        .to raise_error(ArgumentError)
    end
  end
end
