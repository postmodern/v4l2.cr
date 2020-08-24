require "../linux/videodev2"

module V4L2
  class Frequency

    def initialize(tuner : UInt32)
      @struct = Linux::V4L2Frequency.new
      @struct.tuner = tuner
    end

    def initialize(@struct : Linux::V4L2Frequency)
    end

    delegate tuner, to: @struct
    delegate type, to: @struct
    delegate frequency, to: @struct

    @[AlwaysInline]
    def to_u32
      frequency
    end

    def to_unsafe : Pointer(Linux::V4L2Frequency)
      pointerof(@struct)
    end

  end
end
