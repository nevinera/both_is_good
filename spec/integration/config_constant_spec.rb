RSpec.describe "configuration constant" do
  let(:mismatches) { [] }

  let(:config) do
    log = mismatches
    BothIsGood::Configuration.new(nil).tap do |c|
      c.rate = 1.0
      c.on_mismatch = ->(a, b) { log << [a, b] }
    end
  end

  let(:klass) do
    cfg = config
    Class.new do
      include BothIsGood
      both_is_good_configure(cfg)

      def primary_impl = :primary

      def secondary_impl = :secondary

      implemented_twice :the_method, original: :primary_impl, replacement: :secondary_impl
    end
  end

  it "inherits on_mismatch from the config constant" do
    klass.new.the_method
    expect(mismatches).to eq([[:primary, :secondary]])
  end

  it "call-site options override the config constant" do
    cfg = config
    overriding_klass = Class.new do
      include BothIsGood
      both_is_good_configure(cfg)

      def primary_impl = :primary

      def secondary_impl = :secondary

      implemented_twice :the_method,
        original: :primary_impl,
        replacement: :secondary_impl,
        rate: 0.0
    end
    overriding_klass.new.the_method
    expect(mismatches).to be_empty
  end

  it "two classes sharing a config constant get independent copies" do
    cfg = config
    klass_a = Class.new do
      include BothIsGood
      both_is_good_configure(cfg)

      def primary_impl = :a_primary

      def secondary_impl = :a_secondary

      implemented_twice :the_method, original: :primary_impl, replacement: :secondary_impl
    end

    klass_b = Class.new do
      include BothIsGood
      both_is_good_configure(cfg)

      def primary_impl = :b_primary

      def secondary_impl = :b_secondary

      implemented_twice :the_method, original: :primary_impl, replacement: :secondary_impl
    end

    klass_a.new.the_method
    klass_b.new.the_method
    expect(mismatches).to eq([[:a_primary, :a_secondary], [:b_primary, :b_secondary]])
  end

  describe "inheriting from global config" do
    around do |example|
      example.run
      BothIsGood::Configuration.instance_variable_set(:@global, nil)
    end

    it "class config takes precedence over global config" do
      global_mismatches = []
      BothIsGood.configure { |c| c.on_mismatch = ->(a, b) { global_mismatches << [a, b] } }
      klass.new.the_method
      expect(mismatches).not_to be_empty
      expect(global_mismatches).to be_empty
    end
  end
end
