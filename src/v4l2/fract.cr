module V4L2
  record Fract, numerator : UInt32, denominator : UInt32 do

    def to_f
      numerator.to_f / denominator.to_f
    end

    def to_s
      "#{numerator}/#{denominator}"
    end

  end
end
