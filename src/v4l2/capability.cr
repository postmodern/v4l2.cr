require "../linux/videodev2"

module V4L2
  class Capability

    alias Cap = Linux::V4L2Cap

    def initialize
      @struct = Linux::V4L2Capability.new
    end

    delegate version, to: @struct

    delegate capabilities, to: @struct

    {% for cap in Cap.constants %}
      {% begin %}
      @[AlwaysInline]
      def {{ cap.id.downcase }}?
        capabilities.includes?(Cap::{{ cap.id }})
      end
      {% end %}
    {% end %}

    def driver : String
      String.new(@struct.driver.to_slice)
    end

    def card : String
      String.new(@struct.card.to_slice)
    end

    def device_caps?
      @struct.capabilities.includes?(Linux::V4L2Cap::DEVICE_CAPS)
    end

    delegate device_caps, to: @struct

    def to_unsafe : Pointer(Linux::V4L2Capability)
      pointerof(@struct)
    end

  end
end
