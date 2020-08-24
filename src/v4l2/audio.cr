module V4L2
  class Audio

    def initialize
      @struct = Linux::V4L2Audio.new
    end

    def initialize(@struct : Linux::V4L2Audio)
    end

    delegate index, to: @struct

    def name : String
      String.new(@struct.name.to_slice)
    end

    delegate capability, to: @struct

    delegate mode, to: @struct

    def to_unsafe : Pointer(Linux::V4L2Audio)
      pointerof(@struct)
    end

  end
end
