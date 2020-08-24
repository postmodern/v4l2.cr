module V4L2
  class AudioOut

    def initialize
      @struct = Linux::V4L2AudioOut.new
    end

    def initialize(@struct : Linux::V4L2AudioOut)
    end

    delegate index, to: @struct

    def name : String
      String.new(@struct.name.to_slice)
    end

    delegate capability, to: @struct

    delegate mode, to: @struct

    def to_unsafe : Pointer(Linux::V4L2AudioOut)
      pointerof(@struct)
    end

  end
end
