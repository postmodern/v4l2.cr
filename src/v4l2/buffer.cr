require "../linux/videodev2"

module V4L2
  #
  # Represents a "buffer" which the V4L2 kernel API controls.
  #
  class Buffer

    alias Type = Linux::V4L2BufType

    alias Memory = Linux::V4L2Memory

    alias Flags = Linux::V4L2BufFlags

    alias Field = Linux::V4L2Field

    alias Cap = Linux::V4L2BufCap

    #
    # Initializes the buffer from a pointer to a Linux::V4L2Buffer struct.
    #
    def initialize(buffer_ptr : Linux::V4L2Buffer *)
      @pointer = buffer_ptr
    end

    @struct : Linux::V4L2Buffer?

    #
    # Initializes a new buffer of the given type, memory type, and index.
    #
    def initialize(type : Type, memory : Memory, index : UInt32)
      buffer = Linux::V4L2Buffer.new
      buffer.type   = type
      buffer.memory = memory
      buffer.index  = index

      @struct  = buffer
      @pointer = pointerof(buffer)
    end

    delegate index, to: @pointer.value
    delegate type, to: @pointer.value

    @[AlwaysInline]
    def bytes_used
      @pointer.value.bytesused
    end

    delegate flags, to: @pointer.value
    delegate field, to: @pointer.value
    delegate memory, to: @pointer.value
    delegate length, to: @pointer.value

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

    delegate requested_fd, to: @pointer.value

    def to_unsafe : Pointer(Linux::V4L2Buffer)
      @pointer
    end

  end
end
