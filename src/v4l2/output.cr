module V4L2
  class Output

    def initialize(@struct : Linux::V4L2Output)
    end

    delegate index, to: @struct

    def name : String
      String.new(@struct.name.to_slice)
    end

    delegate type, to: @struct

    delegate audioset, to: @struct

    delegate modulator, to: @struct

    delegate std, to: @struct

    @[AlwaysInline]
    def standard
      std
    end

    delegate capabilities, to: @struct

    def to_unsafe : Pointer(Linux::V4L2Output)
      pointerof(@struct)
    end

  end
end
