require "./struct_wrapper"
require "./frame_sizes"

module V4L2
  class FmtDesc

    include StructWrapper(Linux::V4L2FmtDesc)

    def initialize(@device : Device, @struct : Linux::V4L2FmtDesc)
    end

    struct_getter index
    struct_getter type
    struct_char_array_field description
    struct_getter pixel_format, field: pixelformat

    def each_frame_size(&block : (FrameSizes::Discrete | FrameSizes::Stepwise) ->)
      @device.each_frame_size(@struct.pixelformat,&block)
    end

  end
end
