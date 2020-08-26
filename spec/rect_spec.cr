require "./spec_helper"

Spectator.describe V4L2::Rect do
  let(left)   { 10      }
  let(top)    { 20      }
  let(width)  { 100_u32 }
  let(height) { 80_u32  }

  let(rect_struct) do
    rect = Linux::V4L2Rect.new
    rect.left   = left
    rect.top    = top
    rect.width  = width
    rect.height = height
    rect
  end

  subject { described_class.new(left,top,width,height) }

  describe "#initialize(Linux::V4L2Rect)" do
    subject { described_class.new(rect_struct) }

    it "must initialize #left, #top, #width, and #height" do
      expect(subject.left).to   be == left
      expect(subject.top).to    be == top
      expect(subject.width).to  be == width
      expect(subject.height).to be == height
    end
  end

  describe "#to_unsafe" do
    it "must return a populated Linux::V4L2Rect struct" do
      expect(subject.to_unsafe).to be == rect_struct
    end
  end
end
