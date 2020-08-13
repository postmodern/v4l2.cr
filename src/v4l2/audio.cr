module V4L2
  class Audio

    def initialize(@audio : Linux::V4L2Audio)
    end

    delegate index, to: @audio

    def name
      String.new(@audio.name.to_slice)
    end

    delegate capability, to: @audio

    delegate mode, to: @audio

    def to_unsafe
      pointerof(@audio)
    end

  end
end
