require "../linux/videodev2"
require "./struct_wrapper"

module V4L2
  class Format

    include StructWrapper(Linux::V4L2Format)

    def initialize(type : Buffer::Type)
      @struct = Linux::V4L2Format.new
      @struct.type = type
    end

    def initialize(type : Buffer::Type, &block : (self) ->)
      initialize(type)

      yield self
    end

    struct_getter type

    class Pix < Format

      struct_property width, to: @struct.fmt.pix
      struct_property height, to: @struct.fmt.pix
      struct_property pixel_format, field: pixelformat, to: @struct.fmt.pix

      struct_getter field, to: @struct.fmt.pix
      struct_getter bytes_per_line, field: bytesperline, to: @struct.fmt.pix
      struct_getter size_image, field: sizeimage, to: @struct.fmt.pix

      struct_getter color_space, field: colorspace, to: @struct.fmt.pix
      struct_getter flags, to: @struct.fmt.pix

      struct_getter ycbcr, to: @struct.fmt.pix.enc
      struct_getter hsv, to: @struct.fmt.pix.enc

      struct_getter quality, to: @struct.fmt.pix

      def xfer_func
        Linux::V4L2XFERFunc.new(@struct.fmt.pix.xfer_func)
      end

    end

    class PixMPlane < Format

      struct_getter width, to: @struct.fmt.pix_mp
      struct_getter height, to: @struct.fmt.pix_mp
      struct_getter pixel_format, field: pixelformat, to: @struct.fmt.pix_mp
      struct_getter field, to: @struct.fmt.pix_mp
      struct_getter color_space, field: colorspace, to: @struct.fmt.pix_mp

      def planes
        @struct.fmt.pix_mp.plane_fmt[0,@struct.fmt.pix_mp.num_planes]
      end

      def planes=(new_planes)
        raise NotImplementedError.new("#{self.class}#planes= not yet implemented")
      end

      struct_getter ycbcr, field: ycbcr_enc, to: @struct.fmt.pix_mp
      struct_getter hsv, field: hsv_enc, to: @struct.fmt.pix_mp

      struct_getter xfer_func, to: @struct.fmt.pix_mp

    end

    class Window < Format

      struct_getter left, to: @struct.fmt.win.w
      struct_getter top, to: @struct.fmt.win.w
      struct_getter width, to: @struct.fmt.win.w
      struct_getter height, to: @struct.fmt.win.w

      struct_getter field, to: @struct.fmt.win

      struct_getter chroma_key, field: chromakey, to: @struct.fmt.win

      def clips
        raise NotImplementedError.new("#{self.class}#clips not yet implemented")
      end

      def bitmap
        raise NotImplementedError.new("#{self.class}#bitmap not yet implemented")
      end

    end

    class VBI < Format

      alias Flags = Linux::V4L2VBIFlags

      struct_getter sampling_rate, to: @struct.fmt.vbi
      struct_getter offset, to: @struct.fmt.vbi
      struct_getter samples_per_line, to: @struct.fmt.vbi
      struct_getter sample_format, to: @struct.fmt.vbi
      struct_getter start, to: @struct.fmt.vbi
      struct_getter count, to: @struct.fmt.vbi
      struct_getter flags, to: @struct.fmt.vbi

    end

    class SlicedVBI < Format

      struct_getter service_set, to: @struct.fmt.sliced_vbi
      struct_getter service_lines, to: @struct.fmt.sliced_vbi
      struct_getter io_size, to: @struct.fmt.sliced_vbi

    end

    class SDR < Format

      struct_getter pixel_format, field: pixelformat, to: @struct.fmt.sdr
      struct_getter buffer_size, field: buffersize, to: @struct.fmt.sdr

    end

    class Meta < Format

      struct_getter data_format, field: dataformat, to: @struct.fmt.meta
      struct_getter buffer_size, field: buffersize, to: @struct.fmt.meta

    end

  end
end
