require "../linux/videodev2"
require "./struct_wrapper"

module V4L2
  class Input

    include StructWrapper(Linux::V4L2Input)

    def initialize(@struct : Linux::V4L2Input)
    end

    struct_getter index
    struct_char_array_field name
    struct_getter type
    struct_getter audioset
    struct_getter tuner
    struct_getter standard, field: std
    struct_getter status
    struct_getter capabilities

  end
end
