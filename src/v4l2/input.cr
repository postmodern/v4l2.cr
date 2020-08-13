module V4L2
  class Input

    def initialize(@input : Linux::V4L2Input)
    end

    delegate index, to: @input

    def name
      String.new(@input.name.to_slice)
    end

    delegate type, to: @input

    delegate audioset, to: @input

    delegate tuner, to: @input

    delegate std, to: @input

    @[AlwaysInline]
    def standard
      std
    end

    delegate status, to: @input

    delegate capabilities, to: @input

    def to_unsafe
      pointerof(@input)
    end

  end
end
