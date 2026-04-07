RSpec.describe "Integration test: dynamic switching" do
  let(:log) { [] }
  let(:switched) { [false] }

  let(:klass) do
    events = log
    sw = switched
    Class.new do
      include BothIsGood

      def original_impl = :original

      def replacement_impl = :replacement

      implemented_twice :the_method,
        original: :original_impl,
        replacement: :replacement_impl,
        switch: -> { sw[0] },
        rate: 1.0,
        on_compare: ->(a, b) { events << [:compare, a, b] },
        on_mismatch: ->(a, b) { events << [:mismatch, a, b] }
    end
  end

  context "before throwing the switch" do
    it "returns the original result" do
      expect(klass.new.the_method).to eq(:original)
    end

    it "fires on_compare with (original_result, replacement_result)" do
      klass.new.the_method
      expect(log).to include([:compare, :original, :replacement])
    end

    it "fires on_mismatch with (original_result, replacement_result)" do
      klass.new.the_method
      expect(log).to include([:mismatch, :original, :replacement])
    end
  end

  context "after throwing the switch" do
    before { switched[0] = true }

    it "returns the replacement result" do
      expect(klass.new.the_method).to eq(:replacement)
    end

    it "fires on_compare with (replacement_result, original_result)" do
      klass.new.the_method
      expect(log).to include([:compare, :replacement, :original])
    end

    it "fires on_mismatch with (replacement_result, original_result)" do
      klass.new.the_method
      expect(log).to include([:mismatch, :replacement, :original])
    end

    it "includes swapped names in the names hash" do
      names_seen = []
      sw = switched
      names_klass = Class.new do
        include BothIsGood

        def original_impl = :original

        def replacement_impl = :replacement

        implemented_twice :the_method,
          original: :original_impl,
          replacement: :replacement_impl,
          switch: -> { sw[0] },
          on_compare: ->(_a, _b, names) { names_seen << names }
      end
      names_klass.new.the_method
      expect(names_seen).to eq([{primary: :replacement_impl, secondary: :original_impl}])
    end
  end

  describe "rate interacts with the shadow method" do
    let(:klass) do
      sw = switched
      Class.new do
        include BothIsGood

        def original_impl = :original

        def replacement_impl = :replacement

        implemented_twice :the_method,
          original: :original_impl,
          replacement: :replacement_impl,
          switch: -> { sw[0] },
          rate: 0.0
      end
    end

    it "skips replacement (shadow) when switch is off and rate is 0.0" do
      instance = klass.new
      expect(instance).not_to receive(:replacement_impl)
      instance.the_method
    end

    it "skips original (shadow) when switch is on and rate is 0.0" do
      switched[0] = true
      instance = klass.new
      expect(instance).not_to receive(:original_impl)
      instance.the_method
    end
  end

  describe "error handling flips across the switch" do
    context "when original raises" do
      let(:klass) do
        events = log
        sw = switched
        Class.new do
          include BothIsGood

          def original_impl = raise("original failed")

          def replacement_impl = :replacement

          implemented_twice :the_method,
            original: :original_impl,
            replacement: :replacement_impl,
            switch: -> { sw[0] },
            on_primary_error: ->(e) { events << [:primary_error, e.message] },
            on_secondary_error: ->(e) { events << [:secondary_error, e.message] }
        end
      end

      context "before throwing the switch (original is primary)" do
        it "re-raises the error" do
          expect { klass.new.the_method }.to raise_error(RuntimeError, "original failed")
        end

        it "fires on_primary_error" do
          begin
            klass.new.the_method
          rescue
            nil
          end
          expect(log).to eq([[:primary_error, "original failed"]])
        end
      end

      context "after throwing the switch (original is secondary)" do
        before { switched[0] = true }

        it "swallows the error and returns the replacement result" do
          expect(klass.new.the_method).to eq(:replacement)
        end

        it "fires on_secondary_error" do
          klass.new.the_method
          expect(log).to eq([[:secondary_error, "original failed"]])
        end
      end
    end

    context "when replacement raises" do
      let(:klass) do
        events = log
        sw = switched
        Class.new do
          include BothIsGood

          def original_impl = :original

          def replacement_impl = raise("replacement failed")

          implemented_twice :the_method,
            original: :original_impl,
            replacement: :replacement_impl,
            switch: -> { sw[0] },
            on_primary_error: ->(e) { events << [:primary_error, e.message] },
            on_secondary_error: ->(e) { events << [:secondary_error, e.message] }
        end
      end

      context "before throwing the switch (replacement is secondary)" do
        it "swallows the error and returns the original result" do
          expect(klass.new.the_method).to eq(:original)
        end

        it "fires on_secondary_error" do
          klass.new.the_method
          expect(log).to eq([[:secondary_error, "replacement failed"]])
        end
      end

      context "after throwing the switch (replacement is primary)" do
        before { switched[0] = true }

        it "re-raises the error" do
          expect { klass.new.the_method }.to raise_error(RuntimeError, "replacement failed")
        end

        it "fires on_primary_error" do
          begin
            klass.new.the_method
          rescue
            nil
          end
          expect(log).to eq([[:primary_error, "replacement failed"]])
        end
      end
    end
  end

  describe "arity-1 switch" do
    it "receives a Context::Switching object with the target class and method name" do
      received = []
      sw = switched
      klass = Class.new do
        include BothIsGood

        def original_impl = :original

        def replacement_impl = :replacement

        implemented_twice :the_method,
          original: :original_impl,
          replacement: :replacement_impl,
          switch: ->(ctx) {
                    received << ctx
                    sw[0]
                  }
      end

      klass.new.the_method
      expect(received.map { [_1.target_class, _1.method_name] }).to eq([[klass, :the_method]])
    end
  end
end
