require "../linux/videodev2"

module V4L2
  class Format

    def initialize(type : Buffer::Type)
      @struct = Linux::V4L2Format.new
      @struct.type = type
    end

    def initialize(type : Buffer::Type, &block : (self) ->)
      initialize(type)

      yield self
    end

    delegate type, to: @struct

    def to_unsafe : Pointer(Linux::V4L2Format)
      pointerof(@struct)
    end

    class Pix < Format

      delegate width, to: @struct.fmt.pix
      delegate :width=, to: @struct.fmt.pix

      delegate height, to: @struct.fmt.pix
      delegate :height=, to: @struct.fmt.pix

      delegate pixelformat, to: @struct.fmt.pix
      delegate :pixelformat=, to: @struct.fmt.pix

      def pixel_format
        @struct.fmt.pix.pixelformat
      end

      def pixel_format=(new_pix_format)
        @struct.fmt.pix.pixelformat = new_pix_format
      end

      delegate field, to: @struct.fmt.pix

      delegate bytesperline, to: @struct.fmt.pix

      def bytes_per_line
        @struct.fmt.pix.bytesperline
      end

      delegate sizeimage, to: @struct.fmt.pix

      def size_image
        @struct.fmt.pix.sizeimage
      end

      delegate colorspace, to: @struct.fmt.pix

      def color_space
        @struct.fmt.pix.colorspace
      end

      delegate flags, to: @struct.fmt.pix

      def ycbcr
        @struct.fmt.pix.enc.ycbcr
      end

      def hsv
        @struct.fmt.pix.enc.hsv
      end

      delegate quality, to: @struct.fmt.pix

      def xfer_func
        Linux::V4L2XFERFunc.new(@struct.fmt.pix.xfer_func)
      end

    end

    class PixMPlane < Format

      delegate width, to: @struct.fmt.pix_mp
      delegate height, to: @struct.fmt.pix_mp

      delegate pixelformat, to: @struct.fmt.pix_mp

      def pixel_format
        @struct.fmt.pix_mp.pixelformat
      end

      delegate field, to: @struct.fmt.pix_mp

      delegate colorspace, to: @struct.fmt.pix_mp

      def planes
        @struct.fmt.pix_mp.plane_fmt[0,@struct.fmt.pix_mp.num_planes]
      end

      def planes=(new_planes)
        raise NotImplementedError.new("#{self.class}#planes= not yet implemented")
      end

      def color_space
        @struct.fmt.pix_mp.colorspace
      end

      def ycbcr
        @struct.fmt.pix_mp.enc.ycbcr_enc
      end

      def hsv
        @struct.fmt.pix_mp.enc.hsv_enc
      end

      delegate xfer_func, to: @struct.fmt.pix_mp

    end

    class Window < Format

      delegate left, to: @struct.fmt.win.w
      delegate top, to: @struct.fmt.win.w
      delegate width, to: @struct.fmt.win.w
      delegate height, to: @struct.fmt.win.w

      delegate field, to: @struct.fmt.win

      delegate chromakey, to: @struct.fmt.win

      def chroma_key
        @struct.fmt.win.chromakey
      end

      def clips
        raise NotImplementedError.new("#{self.class}#clips not yet implemented")
      end

      def bitmap
        raise NotImplementedError.new("#{self.class}#bitmap not yet implemented")
      end

    end

    class VBI < Format

      alias Flags = Linux::V4L2VBIFlags

      delegate sampling_rate, to: @struct.fmt.vbi
      delegate offset, to: @struct.fmt.vbi
      delegate samples_per_line, to: @struct.fmt.vbi
      delegate sample_format, to: @struct.fmt.vbi
      delegate start, to: @struct.fmt.vbi
      delegate count, to: @struct.fmt.vbi
      delegate flags, to: @struct.fmt.vbi

    end

    class SlicedVBI < Format

      delegate service_set, to: @struct.fmt.sliced_vbi
      delegate service_lines, to: @struct.fmt.sliced_vbi
      delegate io_size, to: @struct.fmt.sliced_vbi

    end

    class SDR < Format

      delegate pixelformat, to: @struct.fmt.sdr

      def pixel_format
        @struct.fmt.sdr.pixelformat
      end

      delegate buffersize, to: @struct.fmt.sdr

      def buffer_size
        @struct.fmt.sdr.buffersize
      end

    end

    class Meta < Format

      delegate dataformat, to: @struct.fmt.meta

      def data_format
        @struct.fmt.meta.dataformat
      end

      delegate buffersize, to: @struct.fmt.meta

      def buffer_size
        @struct.fmt.meta.buffersize
      end

    end

  end
end
