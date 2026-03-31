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
