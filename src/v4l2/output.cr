require "../linux/videodev2"
require "./struct_wrapper"

module V4L2
  class Output

    include StructWrapper(Linux::V4L2Output)

    def initialize(@struct : Linux::V4L2Output)
    end

    struct_getter index
    struct_char_array_field name
    struct_getter type
    struct_getter audioset
    struct_getter modulator
    struct_getter standard, field: std
    struct_getter capabilities

  end
end
