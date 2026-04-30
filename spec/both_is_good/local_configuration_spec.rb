RSpec.describe BothIsGood::LocalConfiguration do
  let(:owner_class) do
    Class.new do
      def primary_impl = :primary

      private

      def secondary_impl = :secondary
    end
  end

  subject(:local_config) do
    described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl)
  end

  it "is a Configuration" do
    expect(local_config).to be_a(BothIsGood::Configuration)
  end

  it "exposes original" do
    expect(local_config.original).to eq(:primary_impl)
  end

  it "exposes replacement" do
    expect(local_config.replacement).to eq(:secondary_impl)
  end

  describe "original validation" do
    it "raises when original is nil" do
      expect { described_class.new(nil, owner: owner_class, original: nil, replacement: :secondary_impl) }
        .to raise_error(ArgumentError)
    end

    it "raises when original method is not defined on owner" do
      expect { described_class.new(nil, owner: owner_class, original: :nonexistent, replacement: :secondary_impl) }
        .to raise_error(ArgumentError)
    end
  end

  describe "replacement validation" do
    it "raises when replacement is nil" do
      expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: nil) }
        .to raise_error(ArgumentError)
    end

    it "raises when replacement method is not defined on owner" do
      expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :nonexistent) }
        .to raise_error(ArgumentError)
    end
  end

  describe "comparator validation" do
    it "accepts nil" do
      expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: nil) }
        .not_to raise_error
    end

    it "accepts a callable with arity 2" do
      expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: ->(a, b) {}) }
        .not_to raise_error
    end

    it "raises when comparator has wrong arity" do
      expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: ->(a) {}) }
        .to raise_error(ArgumentError)
    end

    it "raises when comparator is not callable" do
      expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: "not callable") }
        .to raise_error(ArgumentError)
    end

    context "when comparator is a class" do
      let(:comparator_class) do
        Class.new do
          def initialize(a, b) = nil

          def call = true
        end
      end

      it "accepts a class with matching initialize and call arities" do
        expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: comparator_class) }
          .not_to raise_error
      end

      it "raises when call is not defined" do
        klass = Class.new { def initialize(a, b) = nil }
        expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: klass) }
          .to raise_error(ArgumentError, /call/)
      end

      it "raises when call has wrong arity" do
        klass = Class.new do
          def initialize(a, b) = nil

          def call(x) = nil
        end
        expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: klass) }
          .to raise_error(ArgumentError, /call/)
      end

      it "raises when initialize has wrong arity" do
        klass = Class.new do
          def initialize(a) = nil

          def call = true
        end
        expect { described_class.new(nil, owner: owner_class, original: :primary_impl, replacement: :secondary_impl, comparator: klass) }
          .to raise_error(ArgumentError, /initialize/)
      end
    end
  end
end
