RSpec.describe BothIsGood::ImplementedTwice do
  let(:runner) { described_class.new(primary: :primary_impl, secondary: :secondary_impl) }

  it "delegates call to an Invocation" do
    expect(BothIsGood::Invocation).to receive(:new).and_call_original
    target = Object.new.tap do |obj|
      obj.define_singleton_method(:primary_impl) { :primary }
      obj.define_singleton_method(:secondary_impl) { :secondary }
    end
    runner.call(target)
  end

  describe "on_compare validation" do
    it "accepts callables with arity 2, 3, or 4" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: ->(a, b) {})
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: ->(a, b, c) {})
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: ->(a, b, c, d) {})
      }.not_to raise_error
    end

    it "raises when supplied with an unsupported arity" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_compare: ->(a) {})
      }.to raise_error(ArgumentError)
    end
  end

  describe "on_mismatch validation" do
    it "accepts callables with arity 2, 3, or 4" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: ->(a, b) {})
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: ->(a, b, c) {})
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: ->(a, b, c, d) {})
      }.not_to raise_error
    end

    it "raises when supplied with an unsupported arity" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_mismatch: ->(a) {})
      }.to raise_error(ArgumentError)
    end
  end

  describe "on_secondary_error validation" do
    it "accepts callables with arity 1, 2, or 3" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: ->(a) {})
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: ->(a, b) {})
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: ->(a, b, c) {})
      }.not_to raise_error
    end

    it "raises when supplied with an unsupported arity" do
      expect {
        described_class.new(primary: :primary_impl, secondary: :secondary_impl, on_secondary_error: ->(a, b, c, d) {})
      }.to raise_error(ArgumentError)
    end
  end
end
