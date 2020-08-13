require "../linux/videodev2"

module V4L2
  class Buffer

    alias Type = Linux::V4L2BufType

    alias Memory = Linux::V4L2Memory

    alias Flags = Linux::V4L2BufFlags

    alias Field = Linux::V4L2Field

    alias Cap = Linux::V4L2BufCap

    def initialize(buffer_ptr : Linux::V4L2Buffer *)
      @pointer = buffer_ptr
    end

    @[AlwaysInline]
    def index : UInt32
      @pointer.value.index
    end

    @[AlwaysInline]
    def type : Type
      @pointer.value.type
    end

    @[AlwaysInline]
    def bytes_used
      @pointer.value.bytesused
    end

    @[AlwaysInline]
    def flags : Flags
      @pointer.value.flags
    end

    @[AlwaysInline]
    def field : Field
      @pointer.value.field
    end

    @[AlwaysInline]
    def memory : Memory
      @pointer.value.memory
    end

    @[AlwaysInline]
    def length
      @pointer.value.length
    end

    def offset : UInt32
      unless memory == Memory::MMAP
        raise "cannot call #offset when memory type is #{memory}"
      end

      @pointer.value.m.offset
    end

    @[Raises(RuntimeError)]
    def user_pointer : Pointer(UInt8)
      unless memory == Memory::USER_PTR
        raise "cannot call #user_pointer when memory type is #{memory}"
      end

      Pointer(UInt8).new(@pointer.value.m.userptr)
    end

    @[Raises(NotImplementedError)]
    def planes
      raise NotImplementedError.new("#planes currently not implemented")
    end

    @[Raises(RuntimeError)]
    def fd : Int32
      unless (type.is_multiplanar? && memory == Memory::DMABUF)
        raise "#fd can only been called when #{type} is multi-planar and memory is #{Memory::DMABUF}"
      end

      @pointer.value.m.fd
    end

    @[AlwaysInline]
    def requested_fd : Int32
      @pointer.value.requested_fd
    end

    @[AlwaysInline]
    def to_unsafe : Linux::V4L2Buffer *
      @pointer
    end

  end
end
