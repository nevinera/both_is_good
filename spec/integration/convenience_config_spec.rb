RSpec.describe "convenience config" do
  describe "two-positional form" do
    let(:klass) do
      Class.new do
        include BothIsGood

        def the_method = :original

        def the_method_v2 = :v2

        implemented_twice :the_method, :the_method_v2
      end
    end

    it "returns the original result" do
      expect(klass.new.the_method).to eq(:original)
    end

    it "aliases the original method out of the way" do
      expect(klass.new).to respond_to(:_bothisgood_original_the_method)
    end
  end

  describe "three-positional form" do
    let(:klass) do
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = :secondary

        implemented_twice :the_method, :primary_impl, :secondary_impl
      end
    end

    it "returns the original result" do
      expect(klass.new.the_method).to eq(:primary)
    end
  end

  describe "with inline on_mismatch" do
    let(:mismatches) { [] }

    let(:klass) do
      log = mismatches
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = :secondary

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_mismatch: ->(a, b) { log << [a, b] }
      end
    end

    it "fires on_mismatch when results differ" do
      klass.new.the_method
      expect(mismatches).to eq([[:primary, :secondary]])
    end

    it "returns the original result regardless of mismatch" do
      expect(klass.new.the_method).to eq(:primary)
    end
  end
end
