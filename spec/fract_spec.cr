require "./spec_helper"

Spectator.describe V4L2::Fract do
  let(numerator) { 1_u32 }
  let(denominator) { 10_u32 }

  subject { described_class.new(numerator,denominator) }

  let(fract_struct) do
    fract = Linux::V4L2Fract.new
    fract.numerator = numerator
    fract.denominator = denominator
    fract
  end

  describe "#initialize(Linux::V4L2Fract)" do
    subject { described_class.new(fract_struct) }

    it "must set numerator" do
      expect(subject.numerator).to be == numerator
    end

    it "must set the denoninator" do
      expect(subject.denominator).to be == denominator
    end
  end

  describe "#to_f" do
    it "should convert the fraction into a Float" do
      expect(subject.to_f).to be == (numerator / denominator)
    end
  end

  describe "#to_s" do
    it "should convert the fraction into a String" do
      expect(subject.to_s).to be == "#{numerator}/#{denominator}"
    end
  end

  describe "#to_unsafe" do
    it "must return a populated Linux::V4L2Fract struct" do
      expect(subject.to_unsafe).to be == fract_struct
    end
  end
end
