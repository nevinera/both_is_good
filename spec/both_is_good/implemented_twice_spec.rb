RSpec.describe BothIsGood::ImplementedTwice do
  let(:owner_class) do
    Class.new do
      include BothIsGood

      def primary_impl = :primary

      def secondary_impl = :secondary
    end
  end

  let(:runner) { described_class.new(owner_class, original: :primary_impl, replacement: :secondary_impl) }

  it "delegates call to an Invocation" do
    expect(BothIsGood::Invocation).to receive(:new).and_call_original
    instance = owner_class.new
    runner.call(BothIsGood::Target.new(instance, :the_method, owner_class))
  end
end
