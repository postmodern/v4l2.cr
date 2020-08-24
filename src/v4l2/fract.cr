require "../linux/videodev2"

module V4L2
  #
  # Represents a fractional value of two integers.
  #
  record Fract, numerator : UInt32, denominator : UInt32 do

    #
    # Initializes a V4L2::Fract from a Linux::V4L2Fract struct.
    #
    def initialize(fract_struct : Linux::V4L2Fract)
      initialize(fract_struct.numerator,fract_struct.denominator)
    end

    #
    # Converts the fraction to a Float.
    #
    def to_f : Float
      numerator.to_f / denominator.to_f
    end

    #
    # Converts the fraction to a String.
    #
    def to_s : String
      "#{numerator}/#{denominator}"
    end

    #
    # Converts the fraction back into a Linux::V4L2Fract.
    #
    def to_unsafe : Linux::V4L2Fract
      fract_struct = Linux::V4L2Fract.new
      fract_struct.numerator   = numerator
      fract_struct.denominator = denominator
      return fract_struct
    end

  end
end
