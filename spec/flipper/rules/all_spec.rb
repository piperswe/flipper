require 'helper'

RSpec.describe Flipper::Rules::All do
  let(:feature_name) { "search" }
  let(:plan_condition) {
    Flipper::Rules::Condition.new(
      {"type" => "property", "value" => "plan"},
      {"type" => "operator", "value" => "eq"},
      {"type" => "string", "value" => "basic"}
    )
  }
  let(:age_condition) {
    Flipper::Rules::Condition.new(
      {"type" => "property", "value" => "age"},
      {"type" => "operator", "value" => "gte"},
      {"type" => "integer", "value" => 21}
    )
  }
  let(:any_rule) {
    Flipper::Rules::Any.new(
      plan_condition,
      age_condition
    )
  }
  let(:rule) {
    Flipper::Rules::All.new(
      plan_condition,
      age_condition
    )
  }

  describe "#initialize" do
    it "flattens rules" do
      instance = Flipper::Rules::Any.new([[plan_condition, age_condition]])
      expect(instance.rules).to eq([
        plan_condition,
        age_condition,
      ])
    end
  end

  describe ".build" do
    context "for Array of Hashes" do
      it "builds instance" do
        instance = Flipper::Rules::All.build([plan_condition.value, age_condition.value])
        expect(instance).to be_instance_of(Flipper::Rules::All)
        expect(instance.rules).to eq([
          plan_condition,
          age_condition,
        ])
      end
    end

    context "for nested Array of Hashes" do
      it "builds instance" do
        instance = Flipper::Rules::All.build([[plan_condition.value, age_condition.value]])
        expect(instance).to be_instance_of(Flipper::Rules::All)
        expect(instance.rules).to eq([
          plan_condition,
          age_condition,
        ])
      end
    end

    context "for Array with All rule" do
      it "builds instance" do
        instance = Flipper::Rules::All.build(any_rule.value)
        expect(instance).to be_instance_of(Flipper::Rules::All)
        expect(instance.rules).to eq([any_rule])
      end
    end
  end

  describe "#value" do
    it "returns type and value" do
      expect(rule.value).to eq({
        "type" => "All",
        "value" => [
          plan_condition.value,
          age_condition.value,
        ],
      })
    end
  end

  describe "#eql?" do
    it "returns true if equal" do
      other_rule = Flipper::Rules::All.new(
        Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "plan"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "string", "value" => "basic"}
        ),
        Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => 21}
        )
      )
      expect(rule).to eql(other_rule)
      expect(rule == other_rule).to be(true)
    end

    it "returns false if not equal" do
      other_rule = Flipper::Rules::All.new(
        Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "plan"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "string", "value" => "premium"}
        ),
        Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => 21}
        )
      )
      expect(rule).not_to eql(other_rule)
      expect(rule == other_rule).to be(false)
    end

    it "returns false if not rule" do
      expect(rule).not_to eql(Object.new)
      expect(rule == Object.new).to be(false)
    end
  end

  describe "#matches?" do
    let(:rule) {
      Flipper::Rules::All.new(
        Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "plan"},
          {"type" => "operator", "value" => "eq"},
          {"type" => "string", "value" => "basic"}
        ),
        Flipper::Rules::Condition.new(
          {"type" => "property", "value" => "age"},
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => 21}
        )
      )
    }

    it "returns true when all conditions match" do
      actor = Flipper::Actor.new("User;1", "plan" => "basic", "age" => 21)
      expect(rule.matches?(feature_name, actor)).to be(true)
    end

    it "returns false when any condition does NOT match" do
      actor = Flipper::Actor.new("User;1", "plan" => "premium", "age" => 18)
      expect(rule.matches?(feature_name, actor)).to be(false)

      actor = Flipper::Actor.new("User;1", "plan" => "basic", "age" => 20)
      expect(rule.matches?(feature_name, actor)).to be(false)

      actor = Flipper::Actor.new("User;1", "plan" => "premium", "age" => 21)
      expect(rule.matches?(feature_name, actor)).to be(false)
    end
  end
end
