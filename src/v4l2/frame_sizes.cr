require "../linux/videodev2"

module V4L2
  module FrameSizes

    @[AlwaysInline]
    def self.new(frame_size : Linux::V4L2FrmSizeEnum) : Discrete | Stepwise
      case frame_size.type
      in Linux::V4L2FrmSizeTypes::DISCRETE
        FrameSizes::Discrete.new(frame_size.frame_size.discrete)
      in Linux::V4L2FrmSizeTypes::STEPWISE, Linux::V4L2FrmSizeTypes::CONTINUOUS
         FrameSizes::Stepwise.new(frame_size.frame_size.stepwise)
      end
    end

    record Discrete, width : UInt32, height : UInt32 do

      def initialize(discrete_struct : Linux::V4L2FrmSizeDiscrete)
        initialize(discrete_struct.width, discrete_struct.height)
      end

      def to_s
        "#{width}x#{height}"
      end

    end

    record Stepwise, min_width : UInt32, max_width : UInt32, step_width : UInt32,
                     min_height : UInt32, max_height : UInt32, step_height : UInt32 do

      def initialize(stepwise_struct : Linux::V4L2FrmSizeStepWise)
        initialize(
          stepwise_struct.min_width, stepwise_struct.max_width, stepwise_struct.step_width,

          stepwise_struct.min_height, stepwise_struct.max_height, stepwise_struct.step_height
        )
      end

      def to_s
        "#{min_width}x#{min_height} - #{max_width}x#{max_height} step #{step_width}/#{step_height}"
      end

    end
  end
end
