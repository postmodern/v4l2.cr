require "../linux/videodev2"
require "./fract"

module V4L2
  class Standard

    def initialize
      @struct = Linux::V4L2Standard.new
    end

    def initialize(@struct : Linux::V4L2Standard)
    end

    delegate index, to: @struct
    delegate id, to: @struct

    def name : String
      String.new(@struct.name)
    end

    def frameperiod : Fract
      Fract.new(@struct.frameperiod)
    end

    @[AlwaysInline]
    def frame_period
      frameperiod
    end

    delegate framelines, to: @struct

    @[AlwaysInline]
    def frame_lines
      @struct.framelines
    end

    def to_unsafe : Pointer(Linux::V4L2Standard)
      pointerof(@struct)
    end

  end
end
