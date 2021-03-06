require "../linux/videodev2"
require "../linux/v4l2-common"
require "./error"
require "./ioctl"
require "./capability"
require "./fmt_desc"
require "./format"
require "./frame_sizes"
require "./standard"
require "./input"
require "./output"
require "./audio"
require "./audio_out"
require "./modulator"
require "./frequency"
require "./crop_capability"
require "./crop"
require "./buffer"
require "./streams"

module V4L2
  #
  # Represents an opened V4L2 device.
  #
  class Device

    include IOCTL

    #
    # Indicates an attempt to open a V4L2 device failed.
    #
    class OpenFailed < Error

      def initialize(path : String)
        super("#{Error.strerror}: #{path}")
      end

    end

    #
    # Represents a VIDIOC ioctl failed.
    #
    class VIDIOCError < Error

      def initialize(ioctl : String, message = Error.strerror)
        super("#{ioctl}: #{message}")
      end

    end

    #
    # Represents that a V4L2 capability is not supported for the device.
    #
    class UnsupportedCapability < Error
    end

    # The underlying file descriptor.
    getter fd : Int32

    # The capabilities of the V4L2 device.
    getter capability : Capability

    @video_capture        : Streams::VideoCapture?
    @video_output         : Streams::VideoOutput?
    @video_overlay        : Streams::VideoOverlay?
    @vbi_capture          : Streams::VBICapture?
    @vbi_output           : Streams::VBIOutput?
    @sliced_vbi_capture   : Streams::SlicedVBICapture?
    @sliced_vbi_output    : Streams::SlicedVBIOutput?
    @video_output_overlay : Streams::VideoOutputOverlay?
    @video_capture_mplane : Streams::VideoCaptureMPlane?
    @video_output_mplane  : Streams::VideoOutputMPlane?
    @sdr_capture          : Streams::SDRCapture?
    @sdr_output           : Streams::SDROutput?
    @meta_capture         : Streams::MetaCapture?
    @meta_output	        : Streams::MetaOutput?

    #
    # Initializes the device with the previously opened file descriptor.
    #
    def initialize(@fd : Int32)
      @io = IO::FileDescriptor.new(@fd, blocking: false)
      @io.read_buffering = false
      @io.read_timeout   = Time::Span.new(seconds: 1)

      @capability = query_capability

      @video_capture        = Streams::VideoCapture.new(self) if @capability.video_capture?
      @video_output         = Streams::VideoOutput.new(self) if @capability.video_output?
      @video_overlay        = Streams::VideoOverlay.new(self) if @capability.video_overlay?
      @vbi_capture          = Streams::VBICapture.new(self) if @capability.vbi_capture?
      @vbi_output           = Streams::VBIOutput.new(self) if @capability.vbi_output?
      @sliced_vbi_capture   = Streams::SlicedVBICapture.new(self) if @capability.sliced_vbi_capture?
      @sliced_vbi_output    = Streams::SlicedVBIOutput.new(self) if @capability.sliced_vbi_output?
      @video_output_overlay = Streams::VideoOutputOverlay.new(self) if @capability.video_output_overlay?
      @video_capture_mplane = Streams::VideoCaptureMPlane.new(self) if @capability.video_capture_mplane?
      @video_output_mplane  = Streams::VideoOutputMPlane.new(self) if @capability.video_output_mplane?
      @sdr_capture          = Streams::SDRCapture.new(self) if @capability.sdr_capture?
      @sdr_output           = Streams::SDROutput.new(self) if @capability.sdr_output?
      @meta_capture         = Streams::MetaCapture.new(self) if @capability.meta_capture?
      @meta_output	        = Streams::MetaOutput.new(self) if @capability.meta_output?
    end

    {% for buffer_type in Buffer::Type.constants %}
      {% unless buffer_type.id == "PRIVATE" %}
        {% begin %}
          #
          # The `{{ buffer_type.id }}` stream.
          #
          def {{ buffer_type.id.downcase }}
            @{{ buffer_type.id.downcase }} || \
              raise UnsupportedCapability.new("#{Capability::Cap::{{ buffer_type.id }}} not supported by the device")
          end
        {% end %}
      {% end %}
    {% end %}

    #
    # Opens the V4L2 device at the given path.
    #
    #     V4L2::Device.open("/dev/video0")
    #
    def self.open(path) : Device
      if (fd = LibC.open(path, LibC::O_RDWR | LibC::O_NONBLOCK, 0)) == -1
        raise OpenFailed.new(path)
      end

      return new(fd)
    end

    #
    # Opens the V4L2 device at the given path, yields it, then closes it.
    #
    #     V4L2::Device.open("/dev/video0") do |video|
    #       # ...
    #     end
    #
    def self.open(path, &block : (Device) ->)
      device = open(path)
      yield device
      device.close
    end

    #
    # Queries the V4L2 device capabilities into the Linux::V4L2Capability struct
    # pointer.
    #
    private def query_cap(capability_ptr : Linux::V4L2Capability *)
      if ioctl_blocking(@fd, Linux::VIDIOC_QUERYCAP, capability_ptr) == -1
        raise VIDIOCError.new("VIDIOC_QUERYCAP")
      end
    end

    #
    # Queries the V4L2 device capabilities.
    #
    def query_capability : Capability
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-querycap.html#ioctl-vidioc-querycap
      capability = Capability.new
      query_cap(capability.to_unsafe)
      return capability
    end

    #
    # Enumerates the supported formats for the buffer type.
    #
    protected def each_format(type : Buffer::Type, &blocl : (FmtDesc) ->)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enum-fmt.html#ioctl-vidioc-enum-fmt
      fmt_desc_struct = Linux::V4L2FmtDesc.new
      fmt_desc_struct.type = type
      index = 0

      loop do
        fmt_desc_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUM_FMT, pointerof(fmt_desc_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUMFMT")
          end
        end

        yield FmtDesc.new(self,fmt_desc_struct)
        index += 1
      end

      return self
    end

    #
    # Queries the current format into the Linux::V4L2Format struct pointer.
    #
    private def get_format(format_ptr : Linux::V4L2Format *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-fmt.html#ioctl-vidioc-g-fmt-vidioc-s-fmt-vidioc-try-fmt
      if ioctl_blocking(@fd, Linux::VIDIOC_G_FMT, format_ptr) == -1
        raise VIDIOCError.new("VIDIOC_G_FMT")
      end
    end

    #
    # Queries the current format.
    #
    protected def get_format(format : Format) : Format
      get_format(format.to_unsafe)
      return format
    end

    #
    # Sets the format using the given Linux::V4L2Format struct pointer.
    #
    private def set_format(new_format : Linux::V4L2Format *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-fmt.html#ioctl-vidioc-g-fmt-vidioc-s-fmt-vidioc-try-fmt
      if ioctl_blocking(@fd, Linux::VIDIOC_S_FMT, new_format) == -1
        raise VIDIOCError.new("VIDIOC_S_FMT")
      end

      return new_format
    end

    #
    # Sets the current format.
    #
    protected def set_format(new_format : Format)
      set_format(new_format.to_unsafe)
    end

    alias PixFmt = Linux::V4L2PixFmt

    #
    # Enumerates over each supported frame size for the given Linux::V4L2PixFmt.
    #
    protected def each_frame_size(pixel_format : PixFmt, &block : (FrameSizes::Discrete | FrameSizes::Stepwise) ->)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enum-framesizes.html
      frame_size_enum_struct = Linux::V4L2FrmSizeEnum.new
      frame_size_enum_struct.pixel_format = pixel_format
      index = 0

      loop do
        frame_size_enum_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUM_FRAMESIZES, pointerof(frame_size_enum_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUM_FRAMESIZES")
          end
        end

        yield FrameSizes.new(frame_size_enum_struct)
        index += 1
      end

      return self
    end

    #
    # Requests buffers of the given buffer type, memory type, count, and
    # optionally capability.
    #
    protected def request_buffers(type : Buffer::Type, memory : Buffer::Memory, count : UInt32, capability : Buffer::Cap? = nil)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-reqbufs.html#ioctl-vidioc-reqbufs
      request_buffers_struct = Linux::V4L2RequestBuffers.new
      request_buffers_struct.type   = type
      request_buffers_struct.memory = memory
      request_buffers_struct.count  = count
      request_buffers_struct.capability = capability if capability

      if ioctl_blocking(@fd, Linux::VIDIOC_REQBUFS, pointerof(request_buffers_struct)) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new("VIDIOC_REQBUFS", "does not support type #{type} or memory #{memory}")
        else
          raise VIDIOCError.new("VIDIOC_REQBUFS")
        end
      end

      if request_buffers_struct.count < (count / 2)
        raise VIDIOCError.new("insufficient buffer memory")
      end
    end

    #
    # Queries a buffer using the partially populated Linux::V4L2Buffer struct
    # pointer.
    #
    private def query_buffer(buffer_ptr : Linux::V4L2Buffer *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-querybuf.html#ioctl-vidioc-querybuf
      if ioctl_blocking(@fd, Linux::VIDIOC_QUERYBUF, buffer_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise IndexError.new
        else
          raise VIDIOCError.new("VIDIOC_QUERYBUF")
        end
      end
    end

    #
    # Queries the information related to the given buffer, populating the given
    # buffer.
    #
    protected def query_buffer(buffer : Buffer) : Buffer
      query_buffer(buffer.to_unsafe)
      return buffer
    end

    #
    # Enqueues the given Linux::V4L2Buffer struct pointer.
    #
    private def enqueue_buffer(buffer_ptr : Linux::V4L2Buffer *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-qbuf.html#ioctl-vidioc-qbuf-vidioc-dqbuf
      if ioctl_blocking(@fd, Linux::VIDIOC_QBUF, buffer_ptr) == -1
        raise VIDIOCError.new("VIDIOC_QBUF")
      end
    end

    #
    # Enqueues the given buffer.
    #
    protected def enqueue_buffer(buffer : Buffer)
      enqueue_buffer(buffer.to_unsafe)
    end

    #
    # Enqueues a newly allocated buffer given the buffer type, memory type,
    # index, optional pointer and optional length.
    #
    protected def enqueue_buffer(type : Buffer::Type, memory : Buffer::Memory, index : UInt32, pointer : Pointer(UInt8)? = nil, length : UInt32? = nil)
      buffer_struct = Linux::V4L2Buffer.new
      buffer_struct.type   = type
      buffer_struct.memory = memory
      buffer_struct.index  = index

      case memory
      when Buffer::Memory::USER_PTR
        buffer_struct.m.userptr = pointer.not_nil!.address
        buffer_struct.length    = length.not_nil!
      end

      enqueue_buffer(pointerof(buffer_struct))
    end

    #
    # Dequeus a buffer of the given buffer type and memory type, yielding the
    # buffer. Returns `false` when no buffer has been dequeued/yielded,
    # otherwise returns `true`.
    #
    protected def dequeue_buffer(type : Buffer::Type, memory : Buffer::Memory, &block : (Buffer) ->) : Bool
      buffer_struct = Linux::V4L2Buffer.new
      buffer_struct.type   = type
      buffer_struct.memory = memory

      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-qbuf.html#ioctl-vidioc-qbuf-vidioc-dqbuf
      if ioctl_blocking(@fd, Linux::VIDIOC_DQBUF, pointerof(buffer_struct)) == -1
        case Errno.value
        when Errno::EAGAIN
          return false
        when Errno::EIO
          # Could ignore EIO, see spec.
        else
          raise VIDIOCError.new("VIDIOC_DQBUF")
        end
      end

      yield Buffer.new(pointerof(buffer_struct))
      return true
    end

    #
    # Exports a buffer of the given buffer type and index. Returns a file
    # descriptor for the exported buffer.
    #
    protected def export_buffer(type : Buffer::Type, index : UInt32) : Int32
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-expbuf.html#ioctl-vidioc-expbuf

      expbuf = Linux::V4L2ExportBuffer.new
      expbuf.tyep  = type
      expbuf.index = index

      if ioctl_blocking(@fd, Linux::VIDIOC_EXPBUF, pointerof(expbuf)) == -1
        raise VIDIOCError.new("VIDIOC_EXPBUF")
      end

      return expbuf.fd
    end

    #
    # Exports a buffer of the given type, index, and plane index. Returns a
    # file descriptor for the exported buffer.
    #
    protected def export_buffer(type : Buffer::Type, index : UInt32, plane : UInt32) : Int32
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-expbuf.html#ioctl-vidioc-expbuf

      expbuf = Linux::V4L2ExportBuffer.new
      expbuf.tyep  = type
      expbuf.index = index
      expbuf.plane = i

      if ioctl_blocking(@fd, Linux::VIDIOC_EXPBUF, pointerof(expbuf)) == -1
        raise VIDIOCError.new("VIDIOC_EXPBUF")
      end

      return expbuf.fd
    end

    #
    # Retrieves the current frame buffer.
    #
    def frame_buffer : Linux::V4L2FrameBuffer
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-fbuf.html#ioctl-vidioc-g-fbuf-vidioc-s-fbuf
      fb_struct = Linux::V4L2FrameBuffer.new

      if ioctl_blocking(@fd, Linux::VIDIOC_G_FBUF, pointerof(fb_struct)) == -1
        raise VIDIOCError.new("VIDIOC_G_FBUF")
      end

      return fb_struct
    end

    #
    # Sets the current frame buffer.
    #
    def frame_buffer=(new_fb)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-fbuf.html#ioctl-vidioc-g-fbuf-vidioc-s-fbuf
      if ioctl_blocking(@fd, Linux::VIDIOC_S_FBUF, pointerof(new_fb)) == -1
        raise VIDIOCError.new("VIDIOC_G_FBUF")
      end

      return new_fb
    end

    #
    # Starts or stops video overlay I/O.
    #
    def overlay=(start_or_stop : Bool) : Bool
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-overlay.html#ioctl-vidioc-overlay
      int : Int32 = if start_or_stop; 1
                    else              0
                    end

      if ioctl_blocking(@fd, Linux::VIDIOC_OVERLAY, pointerof(int)) == -1
        raise VIDIOCError.new("VIDIOC_OVERLAY")
      end

      return start_or_stop
    end

    #
    # Starts the stream associated with the given buffer type.
    #
    protected def stream_on!(type : Buffer::Type)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-streamon.html#ioctl-vidioc-streamon-vidioc-streamoff
      if ioctl_blocking(@fd, Linux::VIDIOC_STREAMON, pointerof(type)) == -1
        raise VIDIOCError.new("VIDIOC_STREAMON")
      end
    end

    #
    # Stops the stream associated with the given buffer type.
    #
    protected def stream_off!(type : Buffer::Type)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-streamon.html#ioctl-vidioc-streamon-vidioc-streamoff
      if ioctl_blocking(@fd, Linux::VIDIOC_STREAMON, pointerof(type)) == -1
        raise VIDIOCError.new("VIDIOC_STREAMOFF")
      end
    end

    #
    # Retrieves the streaming paramters, populating the given
    # Linux::V4L2StreamParm struct pointer.
    #
    private def get_parm(parm_ptr : Linux::V4L2StreamParm *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-parm.html
      if ioctl_blocking(@fd, Linux::VIDIOC_G_PARM, parm_ptr) == -1
        raise VIDIOCError.new("VIDIOC_G_PARM")
      end
    end

    #
    # Retrieves the streaming paramters, populating the given StreamParm.
    #
    protected def get_parm(parm : StreamParm) : StreamParm
      get_parm(parm.to_unsafe)
      return parm
    end

    #
    # Sets the streaming parameters, given the Linux::V4L2StreamParm struct
    # pointer.
    #
    private def set_parm(new_parm : Linux::V4L2StreamParm *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-parm.html#ioctl-vidioc-g-parm-vidioc-s-parm
      if ioctl_blocking(@fd, Linux::VIDIOC_S_PARM, new_parm) == -1
        raise VIDIOCError.new("VIDIOC_G_PARM")
      end
    end

    #
    # Sets the streaming parameters.
    #
    protected def set_parm(new_parm : StreamParm)
      set_parm(new_parm.to_unsafe)
    end

    alias StandardID = Linux::V4L2StdID

    #
    # Queries the current video standard.
    #
    def standard : StandardID
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-std.html#ioctl-vidioc-g-std-vidioc-s-std
      std_id = StandardID.new(0)

      if ioctl_blocking(@fd, Linux::VIDIOC_G_STD, pointerof(std_id)) == -1
        raise VIDIOCError.new("VIDIOC_G_STD")
      end

      return std_id
    end

    #
    # Sets the current video standard.
    #
    def standard=(new_std_id : StandardID)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-std.html#ioctl-vidioc-g-std-vidioc-s-std
      if ioctl_blocking(@fd, Linux::VIDIOC_S_STD, pointerof(new_std_id)) == -1
        raise VIDIOCError.new("VIDIOC_S_STD")
      end

      return new_std_id
    end

    #
    # Enumerates over the supported video standards for the V4L2 device,
    # yielding each Standard object.
    #
    def each_standard : self
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enumstd.html#ioctl-vidioc-enumstd
      standard_struct = Linux::V4L2Standard.new
      index = 0

      loop do
        standard_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUMSTD, pointerof(standard_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUMSTD")
          end
        end

        yield Standard.new(standard_struct)
        index += 1
      end

      return self
    end

    #
    # Queries the video input number.
    #
    def input : Int32
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-input.html
      int = LibC::Int.new(0)

      if ioctl_blocking(@fd, Linux::VIDIOC_G_INPUT, pointerof(int)) == -1
        raise VIDIOCError.new("VIDIOC_G_INPUT")
      end

      return int.to_i32
    end

    #
    # Sets the video input number.
    #
    def input=(new_input : Int32) : Int32
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-input.html
      int = new_input.as(LibC::Int)

      if ioctl_blocking(@fd, Linux::VIDIOC_S_INPUT, pointerof(int)) == -1
        raise VIDIOCError.new("VIDIOC_S_INPUT")
      end

      return new_input
    end

    #
    # Enumerates over the video inputs, yielding each Input object.
    #
    def each_input : self
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enuminput.html
      input_struct = Linux::V4L2Input.new
      index = 0

      loop do
        input_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUMINPUT, pointerof(input_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUMSTD")
          end
        end

        yield Input.new(input_struct)
        index += 1
      end

      return self
    end

    # :nodoc:
    def edid(pad : UInt32, start_block : UInt32, blocks : UInt32) : Linux::V4L2EDID
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-edid.html
      edid_struct = Linux::V4L2EDID.new
      edid_struct.pad = pad
      edid_struct.start_block = start_block
      edid_struct.blocks = blocks

      if ioctl_blocking(@fd, Linux::VIDIOC_G_EDID, pointerof(edid_struct)) == -1
        case Errno.value
        when Errno::ENODATA
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_G_EDID")
        end
      end

      return edid_struct
    end

    # :nodoc:
    def edid=(args : NamedTuple(pad: UInt32, blocks: UInt32, edid: Bytes))
      edid_struct = Linux::V4L2EDID.new
      edid_struct.pad         = args[:pad]
      edid_struct.start_block = 0
      edid_struct.blocks      = args[:blocks]
      edid_struct.edid        = args[:edid]

      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-edid.html
      if ioctl_blocking(@fd, Linux::VIDIOC_G_EDID, pointerof(new_edid)) == -1
        case Errno.value
        when Errno::ENODATA, Errno::E2BIG
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_G_EDID")
        end
      end

      return edid_struct
    end

    #
    # Queries the current video output number.
    #
    def output : LibC::Int
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-output.html
      int = LibC::Int.new(0)

      if ioctl_blocking(@fd, Linux::VIDIOC_G_OUTPUT, pointerof(int)) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_G_OUTPUT")
        end
      end

      return int
    end

    #
    # Sets the current video output number.
    #
    def output=(new_output : Int32)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-output.html
      int = new_output.as(LibC::Int)

      if ioctl_blocking(@fd, Linux::VIDIOC_S_OUTPUT, pointerof(int)) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_S_OUTPUT")
        end
      end

      return new_output
    end

    #
    # Enumerates over the video outputs supported by the V4L2 device, yielding
    # each Output object.
    #
    def each_output : self
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enumoutput.html
      output_struct = Linux::V4L2Output.new
      index = 0

      loop do
        output_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUMOUTPUT, pointerof(output_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUMOUTPUT")
          end
        end

        yield Output.new(output_struct)
        index += 1
      end

      return self
    end

    #
    # Queries the current audio input, populating the Linux::V4L2Audio struct
    # pointer.
    #
    private def get_audio(audio_ptr : Linux::V4L2Audio *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-audio.html
      if ioctl_blocking(@fd, Linux::VIDIOC_G_AUDIO, audio_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_G_AUDIO")
        end
      end
    end

    #
    # Retrieves the current audio input.
    #
    def audio : Audio
      audio = Audio.new

      get_audio(audio.to_unsafe)
      return audio
    end

    #
    # Sets the current audio input using the given Linux::V4L2Audio struct
    # pointer.
    #
    private def set_audio(audio_ptr : Linux::V4L2Audio *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-audio.html
      if ioctl_blocking(@fd, Linux::VIDIOC_S_AUDIO, audio_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_S_AUDIO")
        end
      end
    end

    #
    # Sets the current audio input.
    #
    def audio=(new_audio : Audio) : Audio
      set_audio(new_audio.to_unsafe)
      return new_audio
    end

    #
    # Enumerates over each audio input supported by the V4L2 device, yielding
    # each Audio object.
    #
    def each_audio : self
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enumaudio.html
      audio_struct = Linux::V4L2Audio.new
      index = 0

      loop do
        audio_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUMAUDIO, pointerof(audio_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUMAUDIO")
          end
        end

        yield Audio.new(audio_struct)
        index += 1
      end

      return self
    end

    #
    # Enumerates over each audio output supported by the V4L2 device, yielding
    # each AudioOut object.
    #
    def each_audio_out : self
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-enumaudioout.html
      audio_out_struct = Linux::V4L2AudioOut.new
      index = 0

      loop do
        audio_out_struct.index = index

        if ioctl_blocking(@fd, Linux::VIDIOC_ENUMAUDOUT, pointerof(audio_out_struct)) == -1
          case Errno.value
          when Errno::EINVAL
            break
          else
            raise VIDIOCError.new("VIDIOC_ENUMAUDIOOUT")
          end
        end

        yield AudioOut.new(audio_out_struct)
        index += 1
      end

      return self
    end

    #
    # Queries the current modulator, populating the given Linux::V4L2Modulator
    # struct pointer.
    #
    private def get_modulator(modulator_ptr : Linux::V4L2Modulator *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-modulator.html
      if ioctl_blocking(@fd, Linux::VIDIOC_G_MODULATOR, modulator_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise IndexError.new
        else
          raise VIDIOCError.new("VIDIOC_G_MODULATOR")
        end
      end
    end

    #
    # Retrieves the current modulator.
    #
    def modulator(index : UInt32 = 0) : Modulator
      modulator = Modulator.new(index)
      modulator_struct.index = index

      get_modulator(modulator.to_unsafe)
      return modulator
    end

    #
    # Sets the current modulator using the Linux::V4L2Modulator struct pointer.
    #
    private def set_modulator(modulator_ptr : Linux::V4L2Modulator *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-modulator.html
      if ioctl_blocking(@fd, Linux::VIDIOC_S_MODULATOR, modulator_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise IndexError.new
        else
          raise VIDIOCError.new("VIDIOC_S_MODULATOR")
        end
      end
    end

    #
    # Sets the current modulator.
    #
    def modulator=(modulator : Modulator)
      set_modulator(modulator.to_unsafe)
      return modulator
    end

    #
    # Queries the current tuner or modulator radio frequency, populating the
    # given Linux::V4L2Frequency struct pointer.
    #
    private def get_frequency(frequency_ptr : Linux::V4L2Frequency *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-frequency.html
      if ioctl_blocking(@fd, Linux::VIDIOC_G_FREQUENCY, frequency_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_G_FREQUENCY")
        end
      end
    end

    #
    # Retrieves the current tuner or modulator radio frequency, given the
    # tuner or modulator index number.
    #
    def frequency(tuner : UInt32)
      frequency = Frequency.new(tuner)

      get_frequency(frequency.to_unsafe)
      return frequency
    end

    #
    # Sets the current tuner or modulator frequency, using the
    # Linux::V4L2Frequency struct pointer.
    #
    private def set_frequency(frequency_ptr : Linux::V4L2Frequency *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-frequency.html
      if ioctl_blocking(@fd, Linux::VIDIOC_S_FREQUENCY, frequency_ptr) == -1
        case Errno.value
        when Errno::EINVAL
          raise VIDIOCError.new
        else
          raise VIDIOCError.new("VIDIOC_S_FREQUENCY")
        end
      end

      return args
    end

    #
    # Sets the current tuner or modulator frequency.
    #
    def frequency=(frequency : Frequency)
      set_frequency(frequency.to_unsafe)
      return frequency
    end

    #
    # Queries the V4L2 device's supported cropping capabilities, populating the
    # Linux::V4L2CropCap struct pointer.
    #
    private def crop_capabilities(crop_cap_ptr : Linux::V4L2CropCap *)
      # See https://linuxtv.org/downloads/v4l-dvb-apis-new/uapi/v4l/vidioc-cropcap.html#c.VIDIOC_CROPCAP
      if ioctl_blocking(@fd, Linux::VIDIOC_CROPCAP, crop_cap_ptr) == -1
        raise VIDIOCError.new("VIDIOC_CROPCAP")
      end
    end

    #
    # Queries the V4L2 device's supported crop capabilities for the stream
    # associated with the given buffer type.
    #
    protected def crop_capabilities(type : Buffer::Type)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-cropcap.html#vidioc-cropcap
      crop_cap = CropCapability.new(type)

      crop_capabilities(crop_cap.to_unsafe)
      return crop_cap
    end

    #
    # Retrieves the current set crop, populating the Linux::V4L2Crop struct
    # pointer.
    #
    private def get_crop(crop_ptr : Linux::V4L2Crop *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-crop.html#vidioc-g-crop
      if ioctl_blocking(@fd, Linux::VIDIOC_G_CROP, crop_ptr) == -1
        raise VIDIOCError.new("Linux::VIDIOC_G_CROP")
      end
    end

    #
    # Retrieves the current set crop of the stream associated with the given
    # buffer type.
    #
    protected def get_crop(type : Buffer::Type) : Crop
      crop = Crop.new(type)

      get_crop(crop.to_unsafe)
      return crop
    end

    #
    # Sets the current crop, using the Linux::V4L2Crop struct pointer.
    #
    private def set_crop(new_crop_ptr : Linux::V4L2Crop *)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-crop.html
      if ioctl_blocking(@fd, Linux::VIDIOC_S_CROP, new_crop_ptr) == -1
        raise VIDIOCError.new("Linux::VIDIOC_S_CROP")
      end
    end

    #
    # Sets the current crop.
    #
    protected def set_crop(new_crop : Crop)
      set_crop(new_crop.to_unsafe)
    end

    #
    # Attempts to change the current format of the V4L2 device, but does not
    # actually change the current format.
    #
    private def try_format(format_ptr : Linux::V4L2Format *) : Bool
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-fmt.html
      if ioctl_blocking(@fd, Linux::VIDIOC_TRY_FMT, format_ptr) == -1
        raise VIDIOCError.new("VIDIOC_TRY_FMT")
      end

      return true
    end

    #
    # Attempts to change the current format of the V4L2 device, but does not
    # actually change the current format.
    #
    def try_format(new_format : Format) : Bool
      try_format(new_format.to_unsafe)
    end

    alias Priority = Linux::V4L2Priority

    #
    # Queries the access priority of the V4L2 device.
    #
    def priority : Priority
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-priority.html
      priority = Priority.new(0)

      if ioctl_blocking(@fd, Linux::VIDIOC_G_PRIORITY, pointerof(priority)) == -1
        raise VIDIOCError.new("VIDIOC_G_PRIORITY")
      end

      return priority
    end

    #
    # Sets the access priority of the device.
    #
    def priority=(new_priority : Priority) : Priority
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-priority.html
      if ioctl_blocking(@fd, Linux::VIDIOC_S_PRIORITY, pointerof(new_priority)) == -1
        raise VIDIOCError.new("VIDIOC_G_PRIORITY")
      end

      return new_priority
    end

    # :nodoc:
    def sliced_vbi_capabilities(type : Buffer::Type)
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-g-sliced-vbi-cap.html
      sliced_vbi_cap_struct = Linux::V4L2SlicedVBICap.new

      if ioctl_blocking(@fd, Linux::VIDIOC_G_SLICED_VBI_CAP, pointerof(sliced_vbi_cap_struct)) == -1
        raise VIDIOCError.new("VIDIOC_G_SLICED_VBI_CAP")
      end

      return sliced_vbi_cap_struct
    end

    #
    # Log driver status information.
    #
    # Note: This ioctl is optional and not all drivers support it. It was
    # introduced in Linux 2.6.15.
    #
    def log_status
      # See https://www.kernel.org/doc/html/v4.10/media/uapi/v4l/vidioc-log-status.html
      if ioctl_blocking(@fd, Linux::VIDIOC_LOG_STATUS) == -1
        raise VIDIOCError.new("VIDIOC_LOG_STATUS")
      end
    end

    #
    # Queries the read timeout for the V4L2 device's file descriptor.
    #
    def read_timeout : Time::Span
      @io.read_timeout
    end

    #
    # Sets the read timeout for the V4L2 device's file descriptor.
    #
    def read_timeout=(new_timeout : Time::Span)
      @io.read_timeout = new_timeout
    end

    #
    # Waits for the V4L2 device to indicate data is available for reading.
    #
    def wait_readable
      @io.wait_readable
    end

    #
    # Reads data directly from the V4L2 device's file descriptor. Returns
    # the number of bytes read. If no data is currently available, this
    # method will wait.
    #
    def read(buffer : Slice(UInt8)) : Int32
      wait_readable

      unless @capability.capabilities.includes?(Capability::Cap::READWRITE)
        raise UnsupportedCapability.new("reading directly from the device is not supported")
      end

      return @io.read(buffer)
    end

    #
    # Writes data directly to the V4L2 device's file descriptor.
    #
    def write(buffer : Slice(UInt8))
      unless @capability.capabilities.includes?(Capability::Cap::READWRITE)
        raise UnsupportedCapability.new("writing directly from the device is not supported")
      end

      @io.write(buffer)
    end

    #
    # Closes the V4L2 device.
    #
    def close
      @io.close
    end

    #
    # Determines whether the V4L2 device is closed.
    #
    def closed? : Bool
      @io.closed?
    end

    #
    # Returns the underlying file descriptor for the V4L2 device.
    #
    def to_unsafe : Int32
      @fd
    end

    #
    # Ensures the V4L2 device gets closed.
    #
    def finalize
      close
    end

  end
end
