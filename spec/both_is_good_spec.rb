RSpec.describe BothIsGood do
  let(:including_class) do
    Class.new do
      include BothIsGood
    end
  end

  subject(:including_instance) { including_class.new }

  it { is_expected.to be_a(BothIsGood) }
end
