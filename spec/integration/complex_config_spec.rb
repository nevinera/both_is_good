RSpec.describe "complex config" do
  let(:log) { [] }

  describe "rate" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = :secondary

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          rate: 0.0,
          on_compare: ->(a, b) { events << [:compare, a, b] }
      end
    end

    it "skips secondary when rate is 0.0" do
      klass.new.the_method
      expect(log).to be_empty
    end
  end

  describe "comparator" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = 10

        def secondary_impl = 11

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          comparator: ->(a, b) { (a - b).abs <= 1 },
          on_mismatch: ->(a, b) { events << [:mismatch, a, b] }
      end
    end

    it "uses the comparator to determine match - no mismatch when within tolerance" do
      klass.new.the_method
      expect(log).to be_empty
    end
  end

  describe "on_compare" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = :secondary

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_compare: ->(a, b) { events << [:compare, a, b] }
      end
    end

    it "fires on every call" do
      klass.new.the_method
      klass.new.the_method
      expect(log).to eq([[:compare, :primary, :secondary], [:compare, :primary, :secondary]])
    end
  end

  describe "on_mismatch" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = :secondary

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_mismatch: ->(a, b) { events << [:mismatch, a, b] }
      end
    end

    it "fires when results differ" do
      klass.new.the_method
      expect(log).to eq([[:mismatch, :primary, :secondary]])
    end

    it "does not fire when results match" do
      matching_klass = Class.new do
        include BothIsGood

        def primary_impl = :same

        def secondary_impl = :same

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_mismatch: ->(_a, _b) { log << :mismatch }
      end
      matching_klass.new.the_method
      expect(log).to be_empty
    end
  end

  describe "on_primary_error" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = raise("primary failed")

        def secondary_impl = :secondary

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_primary_error: ->(e) { events << [:primary_error, e.message] }
      end
    end

    it "re-raises the primary error" do
      expect { klass.new.the_method }.to raise_error(RuntimeError, "primary failed")
    end

    it "fires on_primary_error before re-raising" do
      begin
        klass.new.the_method
      rescue
        nil
      end
      expect(log).to eq([[:primary_error, "primary failed"]])
    end
  end

  describe "on_secondary_error" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = raise("secondary failed")

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_secondary_error: ->(e) { events << [:secondary_error, e.message] }
      end
    end

    it "swallows the secondary error and returns the primary result" do
      expect(klass.new.the_method).to eq(:primary)
    end

    it "fires on_secondary_error" do
      klass.new.the_method
      expect(log).to eq([[:secondary_error, "secondary failed"]])
    end
  end

  describe "on_hook_error" do
    let(:klass) do
      events = log
      Class.new do
        include BothIsGood

        def primary_impl = :primary

        def secondary_impl = :secondary

        implemented_twice :the_method,
          original: :primary_impl,
          replacement: :secondary_impl,
          on_mismatch: ->(_a, _b) { raise "hook failed" },
          on_hook_error: ->(e) { events << [:hook_error, e.message] }
      end
    end

    it "returns the primary result even when a hook raises" do
      expect(klass.new.the_method).to eq(:primary)
    end

    it "fires on_hook_error with the hook's error" do
      klass.new.the_method
      expect(log).to eq([[:hook_error, "hook failed"]])
    end
  end
end
