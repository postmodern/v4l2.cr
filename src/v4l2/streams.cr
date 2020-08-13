require "./stream"

module V4L2
  module Streams
    class VideoCapture < Stream(Buffer::Type::VIDEO_CAPTURE, Format::Pix)

      include HasParm(StreamParm::Capture)

    end

    class VideoOutput < Stream(Buffer::Type::VIDEO_OUTPUT, Format::Pix)

      include HasParm(StreamParm::Output)

    end

    class VideoOverlay < Stream(Buffer::Type::VIDEO_OVERLAY, Format::Window)
    end

    class VBICapture < Stream(Buffer::Type::VBI_CAPTURE, Format::VBI)
    end

    class VBIOutput < Stream(Buffer::Type::VBI_OUTPUT, Format::VBI)
    end

    class SlicedVBICapture < Stream(Buffer::Type::SLICED_VBI_CAPTURE, Format::SlicedVBI)
    end

    class SlicedVBIOutput < Stream(Buffer::Type::SLICED_VBI_OUTPUT, Format::SlicedVBI)
    end

    class VideoOutputOverlay < Stream(Buffer::Type::VIDEO_OUTPUT_OVERLAY, Format::Window)
    end

    class VideoCaptureMPlane < Stream(Buffer::Type::VIDEO_CAPTURE_MPLANE, Format::PixMPlane)
    end

    class VideoOutputMPlane < Stream(Buffer::Type::VIDEO_OUTPUT_MPLANE, Format::PixMPlane)
    end

    class SDRCapture < Stream(Buffer::Type::SDR_CAPTURE, Format::SDR)
    end

    class SDROutput < Stream(Buffer::Type::SDR_OUTPUT, Format::SDR)
    end

    class MetaCapture < Stream(Buffer::Type::META_CAPTURE, Format::Meta)
    end

    class MetaOutput < Stream(Buffer::Type::META_OUTPUT, Format::Meta)
    end
  end
end
