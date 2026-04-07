module ErrorSpecFixtures
  class SimpleClass; end
end

RSpec.describe BothIsGood::Context::Error do
  let(:klass) { ErrorSpecFixtures::SimpleClass }
  let(:target) { BothIsGood::Target.new(nil, :the_method, klass) }
  let(:error) { RuntimeError.new("boom") }

  subject(:ctx) do
    described_class.new(
      target:,
      args: [1, 2],
      error:,
      dispatched_name: :primary_impl
    )
  end

  it { expect(ctx.target_class).to eq(klass) }
  it { expect(ctx.method_name).to eq(:the_method) }
  it { expect(ctx.args).to eq([1, 2]) }
  it { expect(ctx.error).to eq(error) }
  it { expect(ctx.dispatched_name).to eq(:primary_impl) }
  it { expect(ctx.target_class_name).to eq("ErrorSpecFixtures::SimpleClass") }
  it { expect(ctx.target_class_string).to eq("error_spec_fixtures/simple_class") }
  it { expect(ctx.tag).to eq("error_spec_fixtures/simple_class--the_method") }
end
