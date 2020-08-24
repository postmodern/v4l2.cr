require "../linux/videodev2"

module V4L2
  record Fract, numerator : UInt32, denominator : UInt32 do

    def initialize(fract_struct : Linux::V4L2Fract)
      initialize(fract_struct.numerator,fract_struct.denominator)
    end

    def to_f : Float
      numerator.to_f / denominator.to_f
    end

    def to_s : String
      "#{numerator}/#{denominator}"
    end

    def to_unsafe : Linux::V4L2Fract
      fract_struct = Linux::V4L2Fract.new
      fract_struct.numerator   = numerator
      fract_struct.denominator = denominator
      return fract_struct
    end

  end
end
