require "../linux/videodev2"
require "./struct_wrapper"

module V4L2
  class Capability

    include StructWrapper(Linux::V4L2Capability)

    alias Cap = Linux::V4L2Cap

    def initialize
      @struct = Linux::V4L2Capability.new
    end

    struct_getter version
    struct_getter capabilities

    {% for cap in Cap.constants %}
      {% begin %}
      @[AlwaysInline]
      def {{ cap.id.downcase }}?
        capabilities.includes?(Cap::{{ cap.id }})
      end
      {% end %}
    {% end %}

    struct_char_array_field driver
    struct_char_array_field card

    def device_caps?
      capabilities.includes?(Linux::V4L2Cap::DEVICE_CAPS)
    end

    struct_getter device_caps

  end
end
