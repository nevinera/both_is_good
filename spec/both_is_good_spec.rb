RSpec.describe BothIsGood do
  let(:including_class) { Class.new { include BothIsGood } }
  subject(:including_instance) { including_class.new }

  it { is_expected.to be_a(BothIsGood) }
end
