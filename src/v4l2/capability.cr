require "../linux/videodev2"

module V4L2
  class Capability

    alias Cap = Linux::V4L2Cap

    def initialize
      @capability = Linux::V4L2Capability.new
    end

    delegate version, to: @capability

    delegate capabilities, to: @capability

    {% for cap in Cap.constants %}
      {% begin %}
      @[AlwaysInline]
      def {{ cap.id.downcase }}?
        capabilities.includes?(Cap::{{ cap.id }})
      end
      {% end %}
    {% end %}

    def driver
      String.new(@capability.driver.to_slice)
    end

    def card
      String.new(@capability.card.to_slice)
    end

    def device_caps?
      @capability.capabilities.includes?(Linux::V4L2Cap::DEVICE_CAPS)
    end

    def device_caps : Linux::V4L2Cap
      @capability.device_caps
    end

    def to_unsafe : Pointer(Linux::V4L2Capability)
      pointerof(@capability)
    end

  end
end
