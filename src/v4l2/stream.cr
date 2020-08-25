require "./format"
require "./crop_capability"
require "./crop"
require "./rect"
require "./stream_parm"
require "./buffer"
require "./buffer_queue"
require "./allocated_buffer"

module V4L2
  #
  # Represents a "stream", defined by a V4L2::Buffer::Type and V4L2::Format.
  #
  # See V4L2::Streams for all supported streams.
  #
  class Stream(TYPE,FORMAT)

    #
    # Indicates the stream has not yet been fully initialized.
    #
    class UninitializedError < Error
    end

    @type : Buffer::Type = Buffer::Type.new(TYPE)
    @queue : BufferQueue?
    @buffers : Array(AllocatedBuffer)?

    #
    # Initializes the stream for the V4L2 device.
    #
    def initialize(@device : Device)
    end

    #
    # Returns the buffer queue for the stream. Raises an UninitializedError if
    # the buffer queue has not been initialized.
    #
    def queue : BufferQueue
      @queue ||
        raise UninitializedError.new("#mmap_buffers or #malloc_buffers has not been called yet")
    end

    #
    # Returns the allocated buffers for the stream. Raises an UninitializedError
    # if the buffers have not been allocated.
    #
    def buffers : Array(AllocatedBuffer)
      @buffers ||
        raise UninitializedError.new("#mmap_buffers or #malloc_buffers has not been called yet")
    end

    #
    # Enumerates over each format supported by the stream.
    #
    def each_format(&block : (FmtDesc) ->)
      @device.each_format(@type,&block)
    end

    #
    # Returns the current format.
    #
    def format : FORMAT
      FORMAT.new(@type) do |format|
        @device.get_format(format)
      end
    end

    #
    # Sets the current format.
    #
    def format=(new_format : FORMAT)
      @device.set_format(new_format)
      return new_format
    end

    #
    # Yields a new format and sets the current format.
    #
    def format(&block : (FORMAT) ->)
      self.format = FORMAT.new(@type,&block)
    end

    #
    # Queries the crop capabilities of the stream.
    #
    def crop_capabilities : CropCapability
      @device.crop_capabilities(@type)
    end

    #
    # Queries the current set crop.
    #
    def crop : Rect
      @device.get_crop(@type).rect
    end

    #
    # Sets the current crop.
    #
    def crop=(rect : Rect)
      @device.set_crop(Crop.new(@type,rect))
    end

    #
    # Requests buffers for the stream, of the given memory type, count, and
    # optional capability.
    #
    private def request_buffers!(memory : Buffer::Memory, count : UInt32, capability : Buffer::Cap? = nil) : self
      case memory
      when Buffer::Memory::MMAP, Buffer::Memory::USER_PTR
      else
        raise NotImplementedError.new("requesting buffers of memory type #{memory} currently not supported")
      end

      if count == 0
        raise ArgumentError.new("count must be > 0")
      end

      @device.request_buffers(@type,memory,count,capability)

      @queue = BufferQueue.new(@device,@type,memory,count)
      return self
    end

    #
    # Requests memory-mapped buffers of the given count for the stream.
    #
    def mmap_buffers!(count : UInt32) : self
      request_buffers!(Buffer::Memory::MMAP, count)

      @buffers = Array(AllocatedBuffer).new(count) do |index|
        buffer = queue.query(index.to_u32)

        AllocatedBuffer.mmap(@device.fd, buffer.offset, buffer.length)
      end

      return self
    end

    #
    # Requests user malloced buffers of the given count and length for the
    # stream.
    #
    def malloc_buffers!(count : UInt32, length : UInt32) : self
      request_buffers!(Buffer::Memory::USER_PTR, count)

      @buffers = Array(AllocatedBuffer).new(count) do |index|
        AllocatedBuffer.malloc(length)
      end

      return self
    end

    #
    # Indicates that the stream supports a certain type of V4L2::StreamParm.
    #
    module HasParm(PARM)
      #
      # Queries the streams capabilities.
      #
      def parm : PARM
        PARM.new.tap do |parm|
          @device.get_parm(parm)
        end
      end

      #
      # Sets the streams capabilities.
      #
      def parm=(new_parm : PARM)
        @device.set_param(new_param)
        return new_parm
      end

      #
      # Queries the stream capabilities, yields it to allow modification, then
      # sets the streams capabilities.
      #
      def parm(&block : (PARM) ->)
        parm = self.parm
        yield parm
        self.parm = parm
      end
    end

    #
    # Indicates the stream supports capturing frames.
    #
    module Capture
      #
      # Starts capturing by enqueuing all buffers.
      #
      def start_capturing! : self
        buffers.each_with_index do |buffer,index|
          queue.enqueue(index.to_u32,buffer)
        end

        return self
      end

      #
      # Starts the stream.
      #
      def stream_on! : self
        @device.stream_on!(@type)
        return self
      end

      #
      # Stops the stream.
      #
      def stream_off! : self
        @device.stream_off!(@type)
        return self
      end

      #
      # Begins capturing, yields, then stops capturing.
      #
      def capture!
        start_capturing!
        stream_on!

        yield

        stream_off!
      end

      #
      # Waits for data to become available, then reads an individual frame,
      # yielding the frame.
      #
      def read_frame(&block : (Frame) ->)
        @device.wait_readable

        queue.dequeue do |buffer|
          allocated_buffer = buffers[buffer.index]
          frame            = Frame.new(buffer,allocated_buffer)

          yield frame
        end
      end
    end

  end
end
