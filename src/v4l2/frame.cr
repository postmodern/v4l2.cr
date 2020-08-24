require "./buffer"
require "./allocated_buffer"

module V4L2
  class Frame

    include Indexable(UInt8)

    getter buffer : Buffer

    @data : Slice(UInt8)

    def initialize(@buffer : Buffer, slice : Slice(UInt8))
      @data = slice[0,buffer.bytes_used]
    end

    def initialize(buffer : Buffer, allocated_buffer : AllocatedBuffer)
      initialize(buffer,allocated_buffer.to_slice)
    end

    def size : UInt32
      @data.size
    end

    def unsafe_fetch(index : Int) : UInt8
      if index < 0
        raise(IndexError.new)
      end

      @buffer[index]
    end

    def bytes : Slice(UInt8)
      @data
    end

    def to_slice : Slice(UInt8)
      @data
    end

    def to_unsafe : Pointer(UInt8)
      @data.to_unsafe
    end

  end
end
