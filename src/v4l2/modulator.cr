require "../linux/videodev2"

module V4L2
  class Modulator

    def initialize(index : UInt32)
      @struct = Linux::V4L2Modulator.new
      @struct.index = index
    end

    def initialize(@struct : Linux::V4L2Modulator)
    end

    delegate index, to: @struct

    def name : String
      String.new(@struct.name)
    end

    delegate capability, to: @struct

    @[AlwaysInline]
    def range_low
      @struct.rangelow
    end

    @[AlwaysInline]
    def range_high
      @struct.rangehigh
    end

    def range : Range(UInt32,UInt32)
      (@struct.rangelow..@struct.rangehigh)
    end

    delegate txsubchans, to: @struct

    @[AlwaysInline]
    def tx_sub_channels
      txsubchans
    end

    delegate type, to: @struct

    def to_unsafe : Pointer(Linux::V4L2Modulator)
      pointerof(@struct)
    end

  end
end
