require "./buffer"

module V4L2
  class AllocatedBuffer

    alias Memory = Buffer::Memory

    getter memory : Memory

    getter pointer : Pointer(UInt8)

    getter length : UInt32

    def initialize(@memory : Memory, @pointer : Pointer(UInt8), @length : UInt32)
    end

    def self.mmap(fd : Int32, offset : UInt32, length : UInt32)
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

    def self.malloc(length : UInt32)
      pointer = Pointer(UInt8).malloc(length)

      return new(Memory::USER_PTR, pointer, length)
    end

    @[AlwaysInline]
    def to_slice
      Slice(UInt8).new(@pointer,@length)
    end

    @[AlwaysInline]
    def to_unsafe
      @pointer
    end

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
