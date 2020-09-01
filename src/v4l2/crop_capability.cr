require "../linux/videodev2"
require "./buffer"
require "./rect"
require "./fract"

module V4L2
  class CropCapability

    include StructWrapper(Linux::V4L2CropCap)

    def initialize(type : Buffer::Type)
      @struct = Linux::V4L2CropCap.new
      @struct.type = type
    end

    struct_getter type

    def bounds : Rect
      Rect.new(@struct.bounds)
    end

    def defrect : Rect
      Rect.new(@struct.defrect)
    end

    def pixelaspect : Fract
      Fract.new(@struct.pixelaspect)
    end

    struct_getter pixel_aspect, field: pixelaspect

  end
end
