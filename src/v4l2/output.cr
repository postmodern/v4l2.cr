module V4L2
  class Output

    def initialize(@output : Linux::V4L2Output)
    end

    delegate index, to: @output

    def name
      String.new(@output.name.to_slice)
    end

    delegate type, to: @output

    delegate audioset, to: @output

    delegate modulator, to: @output

    delegate std, to: @output

    @[AlwaysInline]
    def standard
      std
    end

    delegate capabilities, to: @output

    def to_unsafe
      pointerof(@output)
    end

  end
end
