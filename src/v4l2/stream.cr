require "./format"
require "./stream_parm"
require "./buffer"
require "./buffer_queue"
require "./allocated_buffer"

module V4L2
  class Stream(TYPE,FORMAT)

    module HasParm(PARM)
      def parm : PARM
        PARM.new.tap do |parm|
          @device.get_parm(parm)
        end
      end

      def parm=(new_parm : PARM)
        @device.set_param(new_param)
        return new_parm
      end

      def parm(&block : (PARM) ->)
        parm = self.parm
        yield parm
        self.parm = parm
      end
    end

    class UninitializedError < Error
    end

    @type : Buffer::Type = Buffer::Type.new(TYPE)
    @queue : BufferQueue?
    @buffers : Array(AllocatedBuffer)?

    def initialize(@device : Device)
    end

    @[Raises(RuntimeError)]
    def queue : BufferQueue
      @queue ||
        raise UninitializedError.new("#mmap_buffers or #malloc_buffers has not been called yet")
    end

    @[Raises(RuntimeError)]
    def buffers : Array(AllocatedBuffer)
      @buffers ||
        raise UninitializedError.new("#mmap_buffers or #malloc_buffers has not been called yet")
    end

    def each_format(&block : (FmtDesc) ->)
      @device.each_format(@type,&block)
    end

    def format : FORMAT
      FORMAT.new(@type).tap do |format|
        @device.get_format(format)
      end
    end

    def format=(new_format : FORMAT)
      @device.set_format(new_format)
      return new_format
    end

    def format(&block : (FORMAT) ->)
      self.format = FORMAT.new(@type,&block)
    end

    @[Raises(NotImplementedError, ArgumentError)]
    def request_buffers!(memory : Buffer::Memory, count : UInt32, capability : Buffer::Cap? = nil) : self
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

    def mmap_buffers!(count : UInt32) : self
      request_buffers!(Buffer::Memory::MMAP, count)

      @buffers = Array(AllocatedBuffer).new(count) do |index|
        buffer = queue.query(index.to_u32)

        AllocatedBuffer.mmap(@device.fd, buffer.offset, buffer.length)
      end

      return self
    end

    def malloc_buffers!(count : UInt32, length : UInt32) : self
      request_buffers!(Buffer::Memory::USER_PTR, count)

      @buffers = Array(AllocatedBuffer).new(count) do |index|
        AllocatedBuffer.malloc(length)
      end

      return self
    end

    @[Raises(ArgumentError)]
    def mmap_buffers!(count : Int32) : self
      if count < 0
        raise ArgumentError.new("count must not be negative")
      end

      mmap_buffers!(count.to_u32)
    end

    @[Raises(ArgumentError)]
    def malloc_buffers!(count : Int32, length : Int32) : self
      if count < 0
        raise ArgumentError.new("count must not be negative")
      end

      if length < 0
        raise ArgumentError.new("length must not be negative")
      end

      malloc_buffers!(count.to_u32,length.to_u32)
    end

    def start_capturing! : self
      buffers.each_with_index do |buffer,index|
        queue.enqueue(index.to_u32,buffer)
      end

      return self
    end

    def stream_on! : self
      @device.stream_on!(@type)
      return self
    end

    def read_frame(&block : (Frame) ->)
      @device.wait_readable

      queue.dequeue do |buffer|
        allocated_buffer = buffers[buffer.index]
        frame            = Frame.new(buffer,allocated_buffer)

        yield frame
      end
    end

    def stream_off! : self
      @device.stream_off!(@type)
      return self
    end

  end
end
