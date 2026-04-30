RSpec.describe BothIsGood::Comparators::FloatingPoint do
  subject(:result) { described_class.new(a, b).call }

  context "with equal values" do
    let(:a) { 1.0 }
    let(:b) { 1.0 }

    it { is_expected.to be true }
  end

  context "with values that differ only by floating point imprecision" do
    let(:a) { 0.1 + 0.2 }
    let(:b) { 0.3 }

    it { is_expected.to be true }
  end

  context "with significantly different values" do
    let(:a) { 1.0 }
    let(:b) { 2.0 }

    it { is_expected.to be false }
  end

  context "with infinities of the same sign" do
    let(:a) { Float::INFINITY }
    let(:b) { Float::INFINITY }

    it { is_expected.to be true }
  end

  context "with infinities of opposite sign" do
    let(:a) { Float::INFINITY }
    let(:b) { -Float::INFINITY }

    it { is_expected.to be false }
  end

  context "with NaN" do
    let(:a) { Float::NAN }
    let(:b) { Float::NAN }

    it { is_expected.to be false }
  end
end
