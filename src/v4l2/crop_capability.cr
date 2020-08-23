require "../linux/videodev2"
require "./buffer"
require "./rect"
require "./fract"

module V4L2
  class CropCapability

    def initialize(type : Buffer::Type)
      @struct = Linux::V4L2CropCap.new
      @struct.type = type
    end

    delegate type, to: @struct

    def bounds : Rect
      Rect.new(@struct.bounds)
    end

    def defrect : Rect
      Rect.new(@struct.defrect)
    end

    def pixelaspect : Fract
      Fract.new(@struct.pixelaspect)
    end

    @[AlwaysInline]
    def pixel_aspect
      pixelaspect
    end

    def to_unsafe : Pointer(Linux::V4L2CropCap)
      pointerof(@struct)
    end

  end
end
