require "./buffer"

module V4L2
  #
  # Represents a buffer allocated and controlled by the application, which the
  # V4L2 kernel API will write data into.
  #
  class AllocatedBuffer

    alias Memory = Buffer::Memory

    # The memory type of the allocated buffer.
    getter memory : Memory

    # The raw pointer to the allocated buffer.
    getter pointer : Pointer(UInt8)

    # The length of the allocated buffer.
    getter length : UInt32

    #
    # Initializes an allocated buffer, with the specified memory type, pointer,
    # and length.
    #
    def initialize(@memory : Memory, @pointer : Pointer(UInt8), @length : UInt32)
    end

    #
    # Memory-maps a new buffer using the given file descriptor, offset, and
    # length.
    #
    def self.mmap(fd : Int32, offset : UInt32, length : UInt32) : AllocatedBuffer
      pointer = LibC.mmap(
        nil, # start anywhere
        length,
        LibC::PROT_READ | LibC::PROT_WRITE, # required
        LibC::MAP_SHARED, # recommended
        fd, offset
      )

      if pointer == LibC::MAP_FAILED
        raise("mmap failed") # TODO: find a better error class
      end

      new(Memory::MMAP, pointer.as(Pointer(UInt8)), length)
    end

    #
    # Mallocs a new buffer of the given length.
    #
    def self.malloc(length : UInt32) : AllocatedBuffer
      pointer = Pointer(UInt8).malloc(length)

      return new(Memory::USER_PTR, pointer, length)
    end

    #
    # Returns a slice to the allocated buffer.
    #
    @[AlwaysInline]
    def to_slice : Slice(UInt8)
      Slice(UInt8).new(@pointer,@length)
    end

    #
    # Returns a raw pointer to the allocated buffer.
    #
    @[AlwaysInline]
    def to_unsafe : Pointer(UInt8)
      @pointer
    end

    #
    # De-allocates the buffer.
    #
    def finalize
      case @memory
      when Memory::MMAP
        if LibC.munmap(@pointer, @length) == -1
          # raise munmap
        end
      end
    end

  end
end
