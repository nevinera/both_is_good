module ResultSpecFixtures
  class SimpleClass; end
end

RSpec.describe BothIsGood::Context::Result do
  let(:klass) { ResultSpecFixtures::SimpleClass }
  let(:target) { BothIsGood::Target.new(nil, :the_method, klass) }

  subject(:ctx) do
    described_class.new(
      target:,
      args: [1, 2],
      primary_result: :primary,
      secondary_result: :secondary,
      names: {primary: :primary_impl, secondary: :secondary_impl}
    )
  end

  it { expect(ctx.target_class).to eq(klass) }
  it { expect(ctx.method_name).to eq(:the_method) }
  it { expect(ctx.args).to eq([1, 2]) }
  it { expect(ctx.primary_result).to eq(:primary) }
  it { expect(ctx.secondary_result).to eq(:secondary) }
  it { expect(ctx.primary_name).to eq(:primary_impl) }
  it { expect(ctx.secondary_name).to eq(:secondary_impl) }
  it { expect(ctx.target_class_name).to eq("ResultSpecFixtures::SimpleClass") }
  it { expect(ctx.target_class_string).to eq("result_spec_fixtures/simple_class") }
  it { expect(ctx.tag).to eq("result_spec_fixtures/simple_class--the_method") }
end
