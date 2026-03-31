RSpec.describe BothIsGood do
  around do |example|
    example.run
    BothIsGood::Configuration.instance_variable_set(:@global, nil)
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(BothIsGood.configuration).to be_a(BothIsGood::Configuration)
    end

    it "returns the same instance on repeated calls" do
      expect(BothIsGood.configuration).to be(BothIsGood.configuration)
    end
  end

  describe ".configure" do
    it "yields the global configuration" do
      BothIsGood.configure { |c| expect(c).to be(BothIsGood.configuration) }
    end

    it "allows setting attributes on the global config" do
      BothIsGood.configure { |c| c.rate = 0.5 }
      expect(BothIsGood.configuration.rate).to eq(0.5)
    end
  end
end
