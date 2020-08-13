require "../linux/videodev2"
require "./fract"

module V4L2
  class StreamParm

    def initialize(type : Buffer::Type)
      @struct = Linux::V4L2StreamParm.new
      @struct.type = type
    end

    delegate type, to: @struct

    def to_unsafe : Pointer(Linux::V4L2StreamParm)
      pointerof(@struct)
    end

    class Capture < StreamParm

      def initialize
        initialize(Buffer::Type::VIDEO_CAPTURE)
      end

      def initialize(&block : (CaptureParm) ->)
        initialize

        yield self
      end

      delegate capability, to: @struct.parm.capture
      delegate :capability=, to: @struct.parm.capture

      delegate capture_mode, to: @struct.parm.capture
      delegate :capture_mode=, to: @struct.parm.capture

      delegate time_per_frame, to: @struct.parm.capture
      delegate :time_per_frame=, to: @struct.parm.capture

      delegate extended_mode, to: @struct.parm.capture
      delegate :extended_mode=, to: @struct.parm.capture

      delegate read_buffers, to: @struct.parm.capture
      delegate :read_buffers=, to: @struct.parm.capture

    end

    class Output < StreamParm

      def initialize
        initialize(Buffer::Type::VIDEO_OUTPUT)
      end

      def initialize(&block : (OutputParm) ->)
        initialize

        yield self
      end

      delegate capability, to: @struct.parm.output
      delegate :capability=, to: @struct.parm.output

      delegate capture_mode, to: @struct.parm.output
      delegate :capture_mode=, to: @struct.parm.output

      delegate time_per_frame, to: @struct.parm.output
      delegate :time_per_frame=, to: @struct.parm.output

      delegate extended_mode, to: @struct.parm.output
      delegate :extended_mode=, to: @struct.parm.output

      delegate read_buffers, to: @struct.parm.output
      delegate :read_buffers=, to: @struct.parm.output

    end

  end
end
