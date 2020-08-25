module V4L2
  class Error < RuntimeError

    def self.strerror : String
      String.new(LibC.strerror(Errno.value))
    end

  end
end
