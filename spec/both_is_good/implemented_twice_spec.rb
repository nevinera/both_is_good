RSpec.describe BothIsGood::ImplementedTwice do
  let(:owner_class) do
    Class.new do
      def primary_impl = :primary

      def secondary_impl = :secondary
    end
  end

  let(:runner) { described_class.new(owner_class, primary: :primary_impl, secondary: :secondary_impl) }

  it "delegates call to an Invocation" do
    expect(BothIsGood::Invocation).to receive(:new).and_call_original
    target = owner_class.new
    runner.call(target)
  end
end
