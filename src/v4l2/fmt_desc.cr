require "./frame_sizes"

module V4L2
  class FmtDesc

    def initialize(@device : Device, @struct : Linux::V4L2FmtDesc)
    end

    delegate index, to: @struct

    delegate type, to: @struct

    def description : String
      String.new(@struct.description.to_slice)
    end

    delegate pixelformat, to: @struct

    def each_frame_size(&block : (FrameSizes::Discrete | FrameSizes::Stepwise) ->)
      @device.each_frame_size(pixelformat,&block)
    end

  end
end
