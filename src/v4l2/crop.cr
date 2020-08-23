require "../linux/videodev2"
require "./buffer"
require "./rect"

module V4L2
  class Crop

    @struct : Linux::V4L2Crop

    def initialize(type : Buffer::Type)
      @struct = Linux::V4L2Crop.new
      @struct.type = type
    end

    def initialize(type : Buffer::Type, rect : Rect)
      initialize(type)

      @struct.not_nil!.c = rect.to_unsafe
    end

    def rect : Rect
      Rect.new(@struct.c)
    end

    def to_unsafe : Pointer(Linux::V4L2Crop)
      pointerof(@struct)
    end

  end
end
