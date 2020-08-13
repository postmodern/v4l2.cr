require "ioctl"

module V4L2
  module IOCTL
    @[AlwaysInline]
    protected def ioctl(fd, request, *arguments)
      LibC.ioctl(fd, request, *arguments)
    end

    protected def ioctl_blocking(fd, request, *arguments)
      while ((ret = ioctl(fd, request, *arguments)) == -1) &&
            (Errno.value == Errno::EINTR)
      end

      return ret
    end
  end
end
