RSpec.describe BothIsGood::Comparators::StringCaseInsensitive do
  subject(:result) { described_class.new(a, b).call }

  context "with identical strings" do
    let(:a) { "hello" }
    let(:b) { "hello" }

    it { is_expected.to be true }
  end

  context "with strings that differ only in case" do
    let(:a) { "Hello" }
    let(:b) { "hello" }

    it { is_expected.to be true }
  end

  context "with strings that differ in content" do
    let(:a) { "hello" }
    let(:b) { "world" }

    it { is_expected.to be false }
  end

  context "with two nils" do
    let(:a) { nil }
    let(:b) { nil }

    it { is_expected.to be true }
  end
end
