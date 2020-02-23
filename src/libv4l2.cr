require "./linux/videodev2"

@[Link("v4l2")]
lib LibV4L2
  # TODO: extern FILE *v4l2_log_file;
  alias Char = LibC::Char
  alias Int = LibC::Int
  alias ULong = LibC::ULong
  alias SizeT = LibC::SizeT
  alias SSizeT = LibC::SSizeT

  fun v4l2_open(file : Char *, oflag : Int, ...) : Int
  fun v4l2_close(fd : Int) : Int
  fun v4l2_dup(fd : Int) : Int
  fun v4l2_ioctl(fd : Int, request : ULong, ...) : Int
  fun v4l2_read(fd : Int, buffer : Void* , n : SizeT) : SSizeT
  fun v4l2_write(fd : Int, buffer : Void *, n : SizeT) : SSizeT
  fun v4l2_mmap(start : Void*, length : SizeT, prot : Int, flags : Int, fd : Int, offset : Int64) : Void *
  fun v4l2_munmap(_start : Void *, length : SizeT) : Int

  #
  # Misc functions
  #

  fun v4l2_set_control(fd : Int, cid : Int, value : Int) : Int
  fun v4l2_get_control(fd : Int, cid : Int) : Int

  #
  # Flags for v4l2_fd_open's v4l2_flags argument
  #

  V4L2_DISABLE_CONVERSION = 0x01
  V4L2_ENABLE_ENUM_FMT_EMULATION = 0x02

  fun v4l2_fd_open(fd : Int, v4l2_flags : Int) : Int

  struct LibV4LDevOps
    init : Int -> Void *
    close : Void* ->
    ioctl : (Void *, Int, ULong, Void *) -> Int
    read : (Void *, Int, Void *, SizeT) -> SSizeT
    write : (Void *, Int, Void *, SizeT) -> SSizeT

    reserved1, reserved2, reserved3, reserved4, reserved5, reserved6, reserved7 : Void *
  end
end
