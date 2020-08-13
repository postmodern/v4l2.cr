require "./stream_parm"
require "./format"
require "./buffer"
require "./allocated_buffer"
require "./frame"

module V4L2
  class BufferQueue

    include Indexable(Buffer)
    include Enumerable(Buffer)

    getter type : Buffer::Type

    getter memory : Buffer::Memory

    getter count : UInt32

    def initialize(@device : Device, @type : Buffer::Type, @memory : Buffer::Memory, @count : UInt32)
    end

    def query(index : UInt32) : Buffer
      @device.query_buffer(Buffer.new(@type,@memory,index))
    end

    def dequeue(&block : (Buffer) ->) : Bool
      @device.dequeue_buffer(@type,@memory) do |buffer|
        yield buffer

        @device.enqueue_buffer(buffer)
      end
    end

    @[Raises(IndexError)]
    def enqueue(buffer : Buffer)
      @device.enqueue_buffer(buffer)
    end

    protected def enqueue(index : UInt32, new_buffer : AllocatedBuffer)
      @device.enqueue_buffer(@type,@memory,index,new_buffer.pointer,new_buffer.length)
    end

    def size : UInt32
      @count
    end

    def unsafe_fetch(index : Int) : Buffer
      if index < 0
        raise(IndexError.new)
      end

      query(index.to_u32)
    end

    def each(&block : (Buffer) ->)
      @count.times do |index|
        yield query(index)
      end
    end

  end
end
