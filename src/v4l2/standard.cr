require "../linux/videodev2"
require "./struct_wrapper"
require "./fract"

module V4L2
  class Standard

    include StructWrapper(Linux::V4L2Standard)

    def initialize
      @struct = Linux::V4L2Standard.new
    end

    def initialize(@struct : Linux::V4L2Standard)
    end

    struct_getter index
    struct_getter id
    struct_char_array_field name

    def frameperiod : Fract
      Fract.new(@struct.frameperiod)
    end

    @[AlwaysInline]
    def frame_period
      frameperiod
    end

    struct_getter frame_lines, field: framelines

  end
end
