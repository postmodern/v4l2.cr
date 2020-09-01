require "../linux/videodev2"
require "./struct_wrapper"

module V4L2
  class Frequency

    include StructWrapper(Linux::V4L2Frequency)

    def initialize(tuner : UInt32)
      @struct = Linux::V4L2Frequency.new
      @struct.tuner = tuner
    end

    def initialize(@struct : Linux::V4L2Frequency)
    end

    struct_getter tuner
    struct_getter type
    struct_getter frequency

    @[AlwaysInline]
    def to_u32
      frequency
    end

  end
end
