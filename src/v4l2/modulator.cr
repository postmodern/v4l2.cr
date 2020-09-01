require "../linux/videodev2"
require "./struct_wrapper"

module V4L2
  class Modulator

    include StructWrapper(Linux::V4L2Modulator)

    def initialize(index : UInt32)
      @struct = Linux::V4L2Modulator.new
      @struct.index = index
    end

    def initialize(@struct : Linux::V4L2Modulator)
    end

    struct_getter index
    struct_char_array_field name
    struct_getter capability

    struct_getter range_low, field: rangelow
    struct_getter range_high, field: rangehigh

    def range : Range(UInt32,UInt32)
      (@struct.rangelow..@struct.rangehigh)
    end

    struct_getter tx_sub_channels, field: txsubchans
    struct_getter type

  end
end
