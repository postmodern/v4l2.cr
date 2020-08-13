require "./frame_sizes"

module V4L2
  class FmtDesc

    def initialize(@device : Device, @v4l2_fmt_desc : Linux::V4L2FmtDesc)
    end

    delegate index, to: @v4l2_fmt_desc

    delegate type, to: @v4l2_fmt_desc

    def description
      String.new(@v4l2_fmt_desc.description.to_slice)
    end

    delegate pixelformat, to: @v4l2_fmt_desc

    def each_frame_size(&block : (FrameSizes::Discrete | FrameSizes::Stepwise) ->)
      @device.each_frame_size(pixelformat,&block)
    end

  end
end
