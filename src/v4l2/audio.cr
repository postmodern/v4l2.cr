require "./struct_wrapper"

module V4L2
  class Audio

    include StructWrapper(Linux::V4L2Audio)

    def initialize
      @struct = Linux::V4L2Audio.new
    end

    def initialize(@struct : Linux::V4L2Audio)
    end

    struct_getter index
    struct_char_array_field name
    struct_getter capability
    struct_getter mode

  end
end
