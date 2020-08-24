module V4L2
  class Input

    def initialize(@struct : Linux::V4L2Input)
    end

    delegate index, to: @struct

    def name : String
      String.new(@struct.name.to_slice)
    end

    delegate type, to: @struct

    delegate audioset, to: @struct

    delegate tuner, to: @struct

    delegate std, to: @struct

    @[AlwaysInline]
    def standard
      std
    end

    delegate status, to: @struct

    delegate capabilities, to: @struct

    def to_unsafe : Pointer(Linux::V4L2Input)
      pointerof(@struct)
    end

  end
end
