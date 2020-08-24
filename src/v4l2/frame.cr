require "./buffer"
require "./allocated_buffer"

module V4L2
  #
  # Represents an individual video frame.
  #
  class Frame

    include Indexable(UInt8)

    # The underlying buffer of bytes.
    getter buffer : Buffer

    @data : Slice(UInt8)

    #
    # Initializes the video frame. The buffer represents the buffer metadata
    # and the slice represents where the data was read into.
    #
    def initialize(@buffer : Buffer, slice : Slice(UInt8))
      @data = slice[0,buffer.bytes_used]
    end

    #
    # Initializes the video frame, with the V4L2::Buffer, containing the buffer
    # metadata, and the V4L2::AllocatedBuffer, containing the read data.
    #
    def initialize(buffer : Buffer, allocated_buffer : AllocatedBuffer)
      initialize(buffer,allocated_buffer.to_slice)
    end

    #
    # Returns the size of the video frame.
    #
    def size : UInt32
      @data.size
    end

    #
    # Fetches a byte within the video frame.
    #
    @[Raises(IndexError)]
    def unsafe_fetch(index : Int) : UInt8
      if index < 0
        raise IndexError.new
      end

      @data[index]
    end

    #
    # Returns the bytes of the video frame.
    #
    def bytes : Slice(UInt8)
      @data
    end

    #
    # Converts the video frame to a slice.
    #
    def to_slice : Slice(UInt8)
      @data
    end

    #
    # Converts the video frame to a raw pointer.
    #
    def to_unsafe : Pointer(UInt8)
      @data.to_unsafe
    end

  end
end
