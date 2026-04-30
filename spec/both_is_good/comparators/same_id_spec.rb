RSpec.describe BothIsGood::Comparators::SameId do
  subject(:result) { described_class.new(a, b).call }

  let(:record) { Struct.new(:id) }

  context "with the same id" do
    let(:a) { record.new(1) }
    let(:b) { record.new(1) }

    it { is_expected.to be true }
  end

  context "with different ids" do
    let(:a) { record.new(1) }
    let(:b) { record.new(2) }

    it { is_expected.to be false }
  end

  context "with nil ids" do
    let(:a) { record.new(nil) }
    let(:b) { record.new(nil) }

    it { is_expected.to be true }
  end

  context "with two nils" do
    let(:a) { nil }
    let(:b) { nil }

    it { is_expected.to be true }
  end

  context "with one nil" do
    let(:a) { nil }
    let(:b) { record.new(1) }

    it { is_expected.to be false }
  end
end
