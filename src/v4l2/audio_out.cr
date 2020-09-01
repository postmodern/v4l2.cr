require "./struct_wrapper"

module V4L2
  class AudioOut

    include StructWrapper(Linux::V4L2AudioOut)

    def initialize
      @struct = Linux::V4L2AudioOut.new
    end

    def initialize(@struct : Linux::V4L2AudioOut)
    end

    struct_getter index
    struct_char_array_field name
    struct_getter capability
    struct_getter mode

  end
end
