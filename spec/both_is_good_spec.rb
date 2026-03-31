RSpec.describe BothIsGood do
  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(BothIsGood.configuration).to be_a(BothIsGood::Configuration)
    end

    it "returns the same instance on repeated calls" do
      expect(BothIsGood.configuration).to be(BothIsGood.configuration)
    end
  end

  describe ".configure" do
    around do |example|
      example.run
      BothIsGood::Configuration.instance_variable_set(:@global, nil)
    end

    it "yields the global configuration" do
      BothIsGood.configure { |c| expect(c).to be(BothIsGood.configuration) }
    end

    it "allows setting attributes on the global config" do
      BothIsGood.configure { |c| c.rate = 0.5 }
      expect(BothIsGood.configuration.rate).to eq(0.5)
    end
  end

  describe "ClassMethods" do
    let(:including_class) { Class.new { include BothIsGood } }

    describe "#both_is_good_configuration" do
      it "returns the global configuration when not configured" do
        expect(including_class.both_is_good_configuration).to be(BothIsGood.configuration)
      end

      it "returns the class configuration when configured" do
        including_class.both_is_good_configure(rate: 0.3)
        expect(including_class.both_is_good_configuration).not_to be(BothIsGood.configuration)
      end
    end

    describe "#implemented_twice" do
      describe "argument validation" do
        let(:base_class) do
          Class.new do
            include BothIsGood

            def foo = :foo

            def bar = :bar

            def baz = :baz
          end
        end

        it "raises when no name is supplied" do
          expect { base_class.implemented_twice }.to raise_error(ArgumentError)
        end

        it "raises when no secondary is supplied" do
          expect { base_class.implemented_twice(:foo) }.to raise_error(ArgumentError)
        end

        it "raises when primary and secondary are the same" do
          expect { base_class.implemented_twice(:baz, primary: :foo, secondary: :foo) }.to raise_error(ArgumentError)
        end

        it "raises when mixing positional and keyword primary/secondary" do
          expect { base_class.implemented_twice(:baz, :bar, primary: :foo) }.to raise_error(ArgumentError)
        end

        it "raises with more than 3 positional arguments" do
          expect { base_class.implemented_twice(:baz, :foo, :bar, :baz) }.to raise_error(ArgumentError)
        end
      end

      context "when name is distinct from primary and secondary" do
        let(:including_class) do
          Class.new do
            include BothIsGood

            def primary_impl = :primary

            def secondary_impl = :secondary

            implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl
          end
        end

        subject(:instance) { including_class.new }

        it "defines the named method" do
          expect(instance).to respond_to(:the_method)
        end

        it "delegates to an ImplementedTwice runner" do
          expect_any_instance_of(BothIsGood::ImplementedTwice).to receive(:call).and_call_original
          instance.the_method
        end
      end

      context "when name matches primary" do
        let(:including_class) do
          Class.new do
            include BothIsGood

            def the_method = :original

            def secondary_impl = :secondary

            implemented_twice :the_method, primary: :the_method, secondary: :secondary_impl
          end
        end

        subject(:instance) { including_class.new }

        it "aliases the original primary out of the way" do
          expect(instance).to respond_to(:_bothisgood_primary_the_method)
        end

        it "returns the original primary result" do
          expect(instance.the_method).to eq(:original)
        end
      end

      context "with two positional args" do
        let(:including_class) do
          Class.new do
            include BothIsGood

            def foo = :primary

            def foo_two = :secondary

            implemented_twice :foo, :foo_two
          end
        end

        it "uses the first arg as both the method name and primary" do
          expect(including_class.new.foo).to eq(:primary)
        end

        it "aliases the original primary out of the way" do
          expect(including_class.new).to respond_to(:_bothisgood_primary_foo)
        end
      end

      context "with three positional args" do
        let(:including_class) do
          Class.new do
            include BothIsGood

            def foo_one = :primary

            def foo_two = :secondary

            implemented_twice :foo, :foo_one, :foo_two
          end
        end

        it "defines the named method delegating to primary" do
          expect(including_class.new.foo).to eq(:primary)
        end
      end

      context "config cascade" do
        let(:mock_global) { BothIsGood::Configuration.new(nil) }

        before { allow(BothIsGood::Configuration).to receive(:global).and_return(mock_global) }

        it "uses the global config when no class config or option is set" do
          mock_global.rate = 0.0
          klass = Class.new do
            include BothIsGood

            def primary_impl = :primary

            def secondary_impl = :secondary

            implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl
          end
          expect(klass.new.instance_eval { secondary_impl }).to eq(:secondary)
          allow_any_instance_of(BothIsGood::Invocation).to receive(:rand).and_return(0.5)
          # rate: 0.0 from global means secondary is never called
          expect_any_instance_of(Object).not_to receive(:secondary_impl)
          klass.new.the_method
        end

        it "uses the class config when set" do
          hook = ->(a, b) {}
          klass = Class.new do
            include BothIsGood
            both_is_good_configure(on_compare: hook)

            def primary_impl = :primary

            def secondary_impl = :secondary

            implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl
          end
          expect(hook).to receive(:call).with(:primary, :secondary)
          klass.new.the_method
        end

        it "call-site options override class config" do
          klass = Class.new do
            include BothIsGood
            both_is_good_configure(rate: 0.0)

            def primary_impl = :primary

            def secondary_impl = :secondary

            implemented_twice :the_method, primary: :primary_impl, secondary: :secondary_impl, rate: 1.0
          end
          expect_any_instance_of(klass).to receive(:secondary_impl).and_call_original
          klass.new.the_method
        end
      end

      context "when name matches secondary" do
        let(:including_class) do
          Class.new do
            include BothIsGood

            def primary_impl = :primary

            def the_method = :original

            implemented_twice :the_method, primary: :primary_impl, secondary: :the_method
          end
        end

        subject(:instance) { including_class.new }

        it "aliases the original secondary out of the way" do
          expect(instance).to respond_to(:_bothisgood_secondary_the_method)
        end
      end
    end

    describe "#both_is_good_configure" do
      let(:mock_global) { BothIsGood::Configuration.new(nil) }

      before { allow(BothIsGood::Configuration).to receive(:global).and_return(mock_global) }

      context "with keyword overrides only" do
        it "inherits from global and applies overrides" do
          mock_global.rate = 0.5
          including_class.both_is_good_configure(rate: 0.3)
          expect(including_class.both_is_good_configuration.rate).to eq(0.3)
        end

        it "inherits unoverridden attributes from global" do
          handler = ->(a, b) {}
          mock_global.on_mismatch = handler
          including_class.both_is_good_configure(rate: 0.3)
          expect(including_class.both_is_good_configuration.on_mismatch).to be(handler)
        end
      end

      context "with a base Configuration" do
        let(:base_config) { BothIsGood::Configuration.new(nil).tap { |c| c.rate = 0.7 } }

        it "copies from the supplied config" do
          including_class.both_is_good_configure(base_config)
          expect(including_class.both_is_good_configuration.rate).to eq(0.7)
        end

        it "does not return the same object as the supplied config" do
          including_class.both_is_good_configure(base_config)
          expect(including_class.both_is_good_configuration).not_to be(base_config)
        end
      end

      context "with a base Configuration and overrides" do
        let(:base_config) { BothIsGood::Configuration.new(nil).tap { |c| c.rate = 0.7 } }

        it "applies overrides on top of the supplied config" do
          including_class.both_is_good_configure(base_config, rate: 0.1)
          expect(including_class.both_is_good_configuration.rate).to eq(0.1)
        end
      end
    end
  end
end
