require "./types"
require "./v4l2-common"
require "./v4l2-controls"

# Four-character-code (FOURCC)
macro v4l2_fourcc(a,b,c,d)
  {{ a }}.as(U32) | ({{ b }}.as(U32) << 8) | ({{ c }}.as(U32) << 16) | ({{ d }}.as(U32) << 24)
end

macro v4l2_ctrl_id2class(id)
  (({{ id }}) & 0x0fff0000_u34)
end

macro v4l2_ctrl_id2which(id)
  (({{ id }}) & 0x0fff0000_u34)
end

macro v4l2_ctrl_driver_priv(id)
  ((({{ id }}) & 0xffff) >= 0x1000)
end

lib Linux
  VIDEO_MAX_FRAME = 32
  VIDEO_MAX_PLANES = 8

  enum V4L2Field
    ANY           = 0 # driver can choose from none,
                      #  top, bottom, interlaced
                      #  depending on whatever it thinks
                      #  is approximate ...
    NONE          = 1 # this device has no fields ...
    TOP           = 2 # top field only
    BOTTOM        = 3 # bottom field only
    INTERLACED    = 4 # both fields interlaced
    SEQ_TB        = 5 # both fields sequential into one
                      # buffer, top-bottom order
    SEQ_BT        = 6 # same as above + bottom-top order
    ALTERNATE     = 7 # both fields alternating into
                      # separate buffers
    INTERLACED_TB = 8 # both fields interlaced, top field
                      # first and the top field is
                      # transmitted first
    INTERLACED_BT = 9 # both fields interlaced, top field
                      # first and the bottom field is
                      # transmitted first

    @[AlwaysInline]
    def has_top?
      self == TOP    ||
      is_interlaced? ||
      is_sequential?
    end

    @[AlwaysInline]
    def has_bottom?
      self == BOTTOM ||
      is_interlaced?
      is_sequential?
    end

    @[AlwaysInline]
    def has_both?
      is_interlaced? || is_sequential?
    end

    @[AlwaysInline]
    def has_top_or_bottom?
      self == TOP ||
      self == BOTTOM ||
      self == ALTERNATE
    end

    @[AlwaysInline]
    def is_interlaced?
      self == INTERLACED ||
      self == INTERLACED_TB ||
      self == INTERLACED_BT
    end

    @[AlwaysInline]
    def is_sequential?
      self == SEQ_TB ||
      self == SEQ_BT
    end
  end

  enum V4L2BufType : U32
    VIDEO_CAPTURE        = 1
    VIDEO_OUTPUT         = 2
    VIDEO_OVERLAY        = 3
    VBI_CAPTURE          = 4
    VBI_OUTPUT           = 5
    SLICED_VBI_CAPTURE   = 6
    SLICED_VBI_OUTPUT    = 7
    VIDEO_OUTPUT_OVERLAY = 8
    VIDEO_CAPTURE_MPLANE = 9
    VIDEO_OUTPUT_MPLANE  = 10
    SDR_CAPTURE          = 11
    SDR_OUTPUT           = 12
    META_CAPTURE         = 13
    META_OUTPUT	         = 14
    # Deprecated, do not use
    PRIVATE              = 0x80

    @[AlwaysInline]
    def is_multiplanar?
      self == VIDEO_CAPTURE_MPLANE ||
      self == VIDEO_OUTPUT_MPLANE
    end

    @[AlwaysInline]
    def is_output?
      self == VIDEO_OUTPUT         ||
      self == VIDEO_OUTPUT_MPLANE  ||
      self == VIDEO_OVERLAY        ||
      self == VIDEO_OUTPUT_OVERLAY ||
      self == VBI_OUTPUT           ||
      self == SLICED_VBI_OUTPUT    ||
      self == SDR_OUTPUT           ||
      self == META_OUTPUT
    end
  end

  enum V4L2TunerType
    RADIO      = 1
    ANALOG_TV  = 2
    DIGITAL_TV = 3
    SDR        = 4
    RF         = 5
  end

  enum V4L2Memory
    MMAP             = 1
    USER_PTR         = 2
    OVERLAY          = 3
    DMA_BUF          = 4
  end

  # see also http://vektor.theorem.ca/graphics/ycbcr/
  enum V4L2ColorSpace
    #
    # Default colorspace, i.e. let the driver figure it out.
    # Can only be used with video capture.
    #
    DEFAULT       = 0
    
    # SMPTE 170M: used for broadcast NTSC/PAL SDTV
    SMPTE170M     = 1
    
    # Obsolete pre-1998 SMPTE 240M HDTV standard, superseded by Rec 709
    SMPTE240M     = 2
    
    # Rec.709: used for HDTV
    REC709        = 3
    
    #
    # Deprecated, do not use. No driver will ever return this. This was
    # based on a misunderstanding of the bt878 datasheet.
    #
    BT878         = 4
    
    #
    # NTSC 1953 colorspace. This only makes sense when dealing with
    # really, really old NTSC recordings. Superseded by SMPTE 170M.
    #
    BT470_SYSTEM_M  = 5
    
    #
    # EBU Tech 3213 PAL/SECAM colorspace. This only makes sense when
    # dealing with really old PAL/SECAM recordings. Superseded by
    # SMPTE 170M.
    #
    BT470_SYSTEM_BG = 6
    
    #
    # Effectively shorthand for SRGB, V4L2_YCBCR_ENC_601
    # and V4L2_QUANTIZATION_FULL_RANGE. To be used for (Motion-)JPEG.
    #
    JPEG          = 7
    
    # For RGB colorspaces such as produces by most webcams.
    SRGB          = 8
    
    # opRGB colorspace
    OPRGB         = 9
    
    # BT.2020 colorspace, used for UHDTV.
    BT2020        = 10
    
    # Raw colorspace: for RAW unprocessed images
    RAW           = 11
    
    # DCI-P3 colorspace, used by cinema projectors
    DCI_P3        = 12

    @[AlwaysInline]
    def self.default(is_sdtv : Bool , is_hdtv : Bool)
      is_sdtv ? SMPTE170M : (is_hdtv ? REC709 : SRGB)
    end
  end

  enum V4L2XFERFunc
    #
    # Mapping of Default to actual transfer functions
    # for the various colorspaces:
    #
    # V4L2ColorSpace::SMPTE170M, V4L2ColorSpace::BT470_SYSTEM_M,
    # V4L2ColorSpace::BT470_SYSTEM_BG, V4L2ColorSpace::REC709 and
    # V4L2ColorSpace::BT2020: V4L2_XFER_FUNC_709
    #
    # V4L2ColorSpace::SRGB, V4L2ColorSpace::JPEG: V4L2_XFER_FUNC_SRGB
    #
    # V4L2ColorSpace::OPRGB: V4L2_XFER_FUNC_OPRGB
    #
    # V4L2ColorSpace::SMPTE240M: V4L2_XFER_FUNC_SMPTE240M
    #
    # V4L2ColorSpace::RAW: V4L2_XFER_FUNC_NONE
    #
    # V4L2ColorSpace::DCI_P3: V4L2_XFER_FUNC_DCI_P3
    #
    DEFAULT     = 0
    REC709      = 1
    SRGB        = 2
    OPRGB       = 3
    SMPTE240M   = 4
    NONE        = 5
    DCI_P3      = 6
    SMPTE2084   = 7

    def self.default(colorspace : V4L2ColorSpace)
      case colorspace
      when V4L2ColorSpace::OPRGB     then OPRGB
      when V4L2ColorSpace::SMPTE240M then SMPTE240M
      when V4L2ColorSpace::DCI_P3    then DCI_P3
      when V4L2ColorSpace::RAW       then NONE
      when V4L2ColorSpace::SRGB,
           V4L2ColorSpace::JPEG      then SRGB
      else                                REC709
      end
    end
  end

  enum V4L2YCBCREncoding
    #
    # Mapping of DEFAULT to actual encodings for the
    # various colorspaces:
    #
    # V4L2_COLORSPACE_SMPTE170M, V4L2_COLORSPACE_470_SYSTEM_M,
    # V4L2_COLORSPACE_470_SYSTEM_BG, V4L2_COLORSPACE_SRGB,
    # V4L2_COLORSPACE_OPRGB and V4L2_COLORSPACE_JPEG: 601
    #
    # V4L2_COLORSPACE_REC709 and V4L2_COLORSPACE_DCI_P3: 709
    #
    # V4L2_COLORSPACE_BT2020: BT2020
    #
    # V4L2_COLORSPACE_SMPTE240M: SMPTE240M
    #
    DEFAULT        = 0

    # ITU-R 601 -- SDTV
    ITU601         = 1

    # Rec. 709 -- HDTV
    REC709         = 2

    # ITU-R 601/EN 61966-2-4 Extended Gamut -- SDTV
    XV601          = 3

    # Rec. 709/EN 61966-2-4 Extended Gamut -- HDTV
    XV709          = 4

    #
    # sYCC (Y'CbCr encoding of sRGB), identical to ENC_601. It was added
    # originally due to a misunderstanding of the sYCC standard. It should
    # not be used, instead use 601.
    #
    SYCC           = 5

    # BT.2020 Non-constant Luminance Y'CbCr
    BT2020         = 6

    # BT.2020 Constant Luminance Y'CbcCrc
    BT2020_CONST_LUM = 7

    # SMPTE 240M -- Obsolete HDTV
    SMPTE240M      = 8

    def self.default(colorspace : V4L2ColorSpace)
      case colorspace
      when V4L2ColorSpace::REC709,
           V4L2ColorSpace::DCI_P3    then REC709
      when V4L2ColorSpace::BT2020    then BT2020
      when V4L2ColorSpace::SMPTE240M then SMPTE240M
      else                                ITU601
      end
    end
  end

  enum V4L2HSVEncoding
    # Hue mapped to 0 - 179
    HUE_MAP_180 = 128

    # Hue mapped to 0-255
    HUE_MAP_256 = 129
  end

  enum V4L2Quantization
    #
    # The default for R'G'B' quantization is always full range, except
    # for the BT2020 colorspace. For Y'CbCr the quantization is always
    # limited range, except for COLORSPACE_JPEG: this is full range.
    #
    DEFAULT    = 0
    FULL_RANGE = 1
    LIM_RANGE  = 2

    @[AlwaysInline]
    def self.default(is_rgb_or_hsv : Bool, colorspace : V4L2ColorSpace, ycbcr_enc : V4L2YCBCREncoding)
      if is_rgb_or_hsv && colorspace == V4L2ColorSpace::BT2020
        LIM_RANGE
      elsif is_rgb_or_hsv && colorspace == V4L2ColorSpace::JPEG
        FULL_RANGE
      else
        LIM_RANGE
      end
    end
  end

  enum V4L2Priority : U32
    UNSET       = 0  # not initialized
    BACKGROUND  = 1
    INTERACTIVE = 2
    RECORD      = 3
    DEFAULT     = INTERACTIVE
  end

  struct V4L2Rect
    left, top : S32
    width, height : U32
  end

  struct V4L2Fract
    numerator, denominator : U32
  end

  @[Flags]
  enum V4L2Cap : U32
    VIDEO_CAPTURE         = 0x00000001  # Is a video capture device
    VIDEO_OUTPUT          = 0x00000002  # Is a video output device
    VIDEO_OVERLAY         = 0x00000004  # Can do video overlay
    VBI_CAPTURE           = 0x00000010  # Is a raw VBI capture device
    VBI_OUTPUT            = 0x00000020  # Is a raw VBI output device
    SLICED_VBI_CAPTURE    = 0x00000040  # Is a sliced VBI capture device
    SLICED_VBI_OUTPUT     = 0x00000080  # Is a sliced VBI output device
    RDS_CAPTURE           = 0x00000100  # RDS data capture
    VIDEO_OUTPUT_OVERLAY  = 0x00000200  # Can do video output overlay
    HW_FREQ_SEEK          = 0x00000400  # Can do hardware frequency seek
    RDS_OUTPUT            = 0x00000800  # Is an RDS encoder
    
    # Is a video capture device that supports multiplanar formats
    VIDEO_CAPTURE_MPLANE = 0x00001000
    # Is a video output device that supports multiplanar formats
    VIDEO_OUTPUT_MPLANE  = 0x00002000
    # Is a video mem-to-mem device that supports multiplanar formats
    VIDEO_M2M_MPLANE     = 0x00004000
    # Is a video mem-to-mem device
    VIDEO_M2M            = 0x00008000
    
    TUNER                = 0x00010000  # has a tuner
    AUDIO                = 0x00020000  # has audio support
    RADIO                = 0x00040000  # is a radio device
    MODULATOR            = 0x00080000  # has a modulator
    
    SDR_CAPTURE          = 0x00100000  # Is a SDR capture device
    EXT_PIX_FORMAT       = 0x00200000  # Supports the extended pixel format
    SDR_OUTPUT           = 0x00400000  # Is a SDR output device
    META_CAPTURE         = 0x00800000  # Is a metadata capture device
    
    READWRITE            = 0x01000000  # read/write systemcalls
    ASYNCIO              = 0x02000000  # async I/O
    STREAMING            = 0x04000000  # streaming I/O ioctls
    META_OUTPUT          = 0x08000000 # Is a metadata output device
    
    TOUCH                = 0x10000000  # Is a touch device
    
    DEVICE_CAPS          = 0x80000000  # sets device capabilities field
  end

  struct V4L2Capability
    driver : U8[16]
    card : U8[32]
    bus_info : U8[32]
    version : U32
    capabilities : V4L2Cap
    device_caps : V4L2Cap
    reserved : U32[3]
  end

  union V4L2PixFormatEnc
    ycbcr, hsv: U32
  end

  struct V4L2PixFormat
    width, height : U32
    pixelformat : V4L2PixFormats
    field : U32          # enum v4l2_field
    bytesperline : U32   # for padding, zero if unused
    sizeimage : U32
    colorspace : U32     # enum v4l2_colorspace
    priv : U32           # private data, depends on pixelformat
    flags : U32          # format flags (V4L2_PIX_FMT_FLAG_*)
    enc : V4L2PixFormatEnc
    quality : U32        # enum v4l2_quantization
    xfer_func : U32      # enum v4l2_xfer_func
  end

  enum V4L2PixFormats : U32
    # priv field value to indicates that subsequent fields are valid.
    PRIV_MAGIC = 0xfeedcafe

    # Flags
    FLAG_PREMUL_ALPHA = 0x00000001
  end

  @[Flags]
  enum V4L2FmtFlags : U32
    COMPRESSED             = 0x0001
    EMULATED               = 0x0002
    CONTINUOUS_BYTE_STREAM = 0x0004
    DYN_RESOLUTION         = 0x0008
  end

  struct V4L2FmtDesc
    index : U32 # Format number
    type : U32  # enum v4l2_buf_type
    flags : V4L2FmtFlags
    description : U8[32] # Description string
    pixelformat : V4L2PixFormats # Format fourcc
    reserved : U32[4]
  end

  # Frame Size Enumeration
  enum V4L2FrmSizeTypes : U32
    DISCRETE   = 1
    CONTINUOUS = 2
    STEP_WISE  = 3
  end

  struct V4L2FrmSizeDiscrete
    width, height : U32
  end

  # Frame Rate Enumeration
  enum V4L2FrmIvalTypes : U32
    DISCRETE	 = 1
    CONTINUOUS = 2
    STEP_WISE  = 3
  end

  struct V4L2FrmSizeStepWise
    min_width : U32   # Minimum frame width [pixel]
    max_width : U32   # Maximum frame width [pixel]
    step_wdith : U32  # Frame width step size [pixel]
    min_height : U32  # Minimum frame height [pixel]
    max_height : U32  # Maximum frame height [pixel]
    step_height : U32 # Frame height step size [pixel]
  end

  union V4L2FrmSize
    discrete : V4L2FrmSizeDiscrete
    stepwise : V4L2FrmSizeStepWise
  end

  struct V4L2FrmSizeEnum
    index : U32        # Frame size number
    pixel_format : U32 # Pixel format
    type : V4L2FrmSizeTypes # Frame size type the device supports.

    frame_size : V4L2FrmSize # Frame size

    reserved : U32[2] # Reserved space for future use
  end

  struct V4L2FrmIvalStepWise
    min : V4L2Fract  # Minimum frame interval [s]
    max : V4L2Fract  # Maximum frame interval [s]
    step : V4L2Fract # Frame interval step size [s]
  end

  union V4L2FrmIval
    discrete : V4L2Fract
    stepwise : V4L2FrmIvalStepWise
  end

  struct V4L2FrmIvalEnum
    index : U32        # Frame format index
    pixel_format : U32 # Pixel format
    width : U32        # Frame width
    height : U32       # Frame height
    type : V4L2FrmIvalTypes         # Frame interval type the device supports.

    frame_ival : V4L2FrmIval # Frame interval

    reserved : U32[2] # Reserved space for future use
  end

  struct V4L2TimeCode
    type : V4L2TCTypes
    flags : V4L2TCFlags
    frames : U8
    seconds : U8
    minutes : U8
    hours : U8
    userbits : U8[4]
  end

  enum V4L2TCTypes : U32
    FPS_24 = 1
    FPS_25 = 2
    FPS_30 = 3
    FPS_50 = 4
    FPS_60 = 5
  end

  @[Flags]
  enum V4L2TCFlags : U8
    DROP_FRAME  = 0x0001 # "drop-frame" mode
    COLOR_FRAME = 0x0002
  end

  enum V4L2TCUserBits : U16
    FIELD        = 0x000C
    USER_DEFINED = 0x0000
    CHARS        = 0x0008
  end

  @[Flags]
  enum V4L2JPEGMarkers : U32
    DHT = 1<<3 # Define Huffman Tables
    DQT = 1<<4 # Define Quantization Tables
    DRI = 1<<5 # Define Restart Interval
    COM = 1<<6 # Comment segment
    APP = 1<<7 # App segment, driver will always use APP0
  end

  struct V4L2JPEGCompression
    quality : Int
    appn : Int # Number of APP segment to be written, must be 0..15
    appn_len : Int # Length of data in JPEG APPn segment
    appn_data : Char[60] # Data in the JPEG APPn segment.

    com_len : Int # Length of data in JPEG COM segment
    com_data : Char[60] # Data in JPEG COM segment

    jpeg_markers : V4L2JPEGMarkers # Which markers should go into the JPEG
                                   # output. Unless you exactly know what
                                   # you do, leave them untouched.
                                   # Including less markers will make the
                                   # resulting code smaller, but there will
                                   # be fewer applications which can read it.
                                   # The presence of the APP and COM marker
                                   # is influenced by APP_len and COM_len
                                   # ONLY, not by this property!
  end

  # capabilities for struct V4L2RequestBuffers and V4L2CreateBuffers
  @[Flags]
  enum V4L2BufCap : U32
    MMAP          = (1 << 0)
    USER_PTR      = (1 << 1)
    DMA_BUF       = (1 << 2)
    REQUESTS      = (1 << 3)
    ORPHANED_BUFS = (1 << 4)
  end

  struct V4L2RequestBuffers
    count : U32
    type : U32   # enum v4l2_buf_type
    memory : U32 # enum v4l2_memory
    capabilities : V4L2BufCap
    reserved : U32[1]
  end

  union V4L2PlaneM
    mem_offset : U32
    userptr : ULong
    fd : U32
  end

  struct V4L2Plane
    bytesused : U32
    length : U32
    m : V4L2PlaneM
    data_offset : U32
    reserved : U32[11]
  end

  union V4L2BufferM
    offset : U32
    userptr : ULong
    planes : V4L2Plane *
    fd : S32
  end

  struct V4L2Buffer
    index : U32
    type : U32
    bytesused : U32
    flags : U32
    field : U32
    timestamp : LibC::Timeval
    timecode : V4L2TimeCode
    sequence : U32

    #
    # memory location
    #
    memory : U32
    m : V4L2BufferM
    length : U32
    reserved2 : U32
    request_fd : S32
  end

  @[Flags]
  enum V4L2BufFlags : U32
    MAPPED = 0x00000001
    # Buffer is queued for processing
    QUEUED = 0x00000002
    # Buffer is ready
    DONE = 0x00000004
    # Image is a keyframe (I-frame)
    KEYFRAME = 0x00000008
    # Image is a P-frame
    PFRAME = 0x00000010
    # Image is a B-frame
    BFRAME = 0x00000020
    # Buffer is ready, but the data contained within is corrupted.
    ERROR = 0x00000040
    # Buffer is added to an unqueued request
    IN_REQUEST = 0x00000080
    # timecode field is valid
    TIMECODE = 0x00000100
    # Buffer is prepared for queuing
    PREPARED = 0x00000400
    # Cache handling flags
    NO_CACHE_INVALIDATE = 0x00000800
    NO_CACHE_CLEAN = 0x00001000
    # Timestamp type
    TIMESTAMP_MASK = 0x0000e000
    TIMESTAMP_UNKNOWN = 0x00000000
    TIMESTAMP_MONOTONIC = 0x00002000
    TIMESTAMP_COPY = 0x00004000
    # Timestamp sources.
    TSTAMP_SRC_MASK = 0x00070000
    TSTAMP_SRC_EOF = 0x00000000
    TSTAMP_SRC_SOE = 0x00010000
    # mem2mem encoder/decoder
    LAST = 0x00100000
    # request_fd is valid
    REQUEST_FD = 0x00800000
  end

  struct V4L2ExportBuffer
    type : U32 # enum v4l2_buf_type
    index : U32
    plane : U32
    flags : V4L2BufFlags
    fd : S32
    reserved : U32[11]
  end

  struct V4L2FrameBufferFmt
    width, height : U32
    pixelformat : V4L2PixFormats
    field : U32        # enum v4l2_field
    bytesperline : U32 # for padding, zero if unused
    sizeimage : U32
    colorspace : U32   # enum v4l2_colorspace
    priv : U32         # eserved field, set to 0
  end

  #  Flags for the 'capability' field. Read only
  @[Flags]
  enum V4L2FrameBufferCap : U32
    EXTERN_OVERLAY  = 0x0001
    CHROMAKEY       = 0x0002
    LIST_CLIPPING   = 0x0004
    BITMAP_CLIPPING = 0x0008
    LOCAL_ALPHA     = 0x0010
    GLOBAL_ALPHA    = 0x0020
    LOCAL_INV_ALPHA = 0x0040
    SRC_CHROMAKEY   = 0x0080
  end

  #  Flags for the 'flags' field.
  @[Flags]
  enum V4L2FrameBufferFlags : U32
    PRIMARY         = 0x0001
    OVERLAY         = 0x0002
    CHROMAKEY       = 0x0004
    LOCAL_ALPHA     = 0x0008
    GLOBAL_ALPHA    = 0x0010
    LOCAL_INV_ALPHA = 0x0020
    SRC_CHROMAKEY   = 0x0040
  end

  struct V4L2FrameBuffer
    capability : V4L2FrameBufferCap
    flags : V4L2FrameBufferFlags

    base : Void *

    fmt : V4L2FrameBufferFmt
  end

  struct V4L2Clip
    c : V4L2Rect
    next : V4L2Clip *
  end

  struct V4L2Window
    w : V4L2Rect
    field : U32 # enum v4l2_field
    chromakey : U32
    clips : V4L2Clip *
    clipcount : U32
    bitmap : Void *
    global_alpha : U8
  end

  struct V4L2CaptureParm
    capability : U32      # Supported modes
    capturemode : U32     # Current mode
    timeperframe : V4L2Fract # Time per frame in seconds
    extendedmode : U32    # Driver-specific extensions
    readbuffers : U32     # # of buffers for read
    reserved : U32[4]
  end

  V4L2_MODE_HIGHQUALITY = 0x0001_u32
  V4L2_CAP_TIMEPERFRAME = 0x1000_u32

  struct V4L2OutputParm
    capability : U32      # Supported modes
    capturemode : U32     # Current mode
    timeperframe : V4L2Fract # Time per frame in seconds
    extendedmode : U32    # Driver-specific extensions
    readbuffers : U32     # # of buffers for read
    reserved : U32[4]
  end

  struct V4L2CropCap
    type : U32 # enum v4l2_buf_type
    bounds : V4L2Rect
    defrect : V4L2Rect
    pixelaspect : V4L2Fract
  end

  struct V4L2Crop
    tyep : U32 # enum v4l2_buf_type
    c : V4L2Rect
  end

  struct V4L2Selection
    type : U32
    target : U32
    flags : U32
    r : V4L2Rect
    reserved : U32[9]
  end

  enum V4L2StdID : U64
    # one bit for each
    PAL_B          = 0x00000001
    PAL_B1         = 0x00000002
    PAL_G          = 0x00000004
    PAL_H          = 0x00000008
    PAL_I          = 0x00000010
    PAL_D          = 0x00000020
    PAL_D1         = 0x00000040
    PAL_K          = 0x00000080
    
    PAL_M          = 0x00000100
    PAL_N          = 0x00000200
    PAL_Nc         = 0x00000400
    PAL_60         = 0x00000800
    
    NTSC_M         = 0x00001000 # BTSC
    NTSC_M_JP      = 0x00002000 # EIA-J
    NTSC_443       = 0x00004000
    NTSC_M_KR      = 0x00008000 # FM A2
    
    SECAM_B        = 0x00010000
    SECAM_D        = 0x00020000
    SECAM_G        = 0x00040000
    SECAM_H        = 0x00080000
    SECAM_K        = 0x00100000
    SECAM_K1       = 0x00200000
    SECAM_L        = 0x00400000
    SECAM_LC       = 0x00800000
    
    # ATSC/HDTV
    ATSC_8_VSB     = 0x01000000
    ATSC_16_VSB    = 0x02000000

    #
    # "Common" NTSC/M - It should be noticed that V4L2_STD_NTSC_443 is
    # Missing here.
    #
    NTSC           = (NTSC_M | NTSC_M_JP | NTSC_M_KR)

    # Secam macros
    SECAM_DK       = (SECAM_D | SECAM_K | SECAM_K1)

    # All Secam Standards
    SECAM          = (SECAM_B |SECAM_G |SECAM_H | SECAM_DK | SECAM_L | SECAM_LC)

    # PAL macros
    PAL_BG         = (PAL_B |PAL_B1 | PAL_G)

    PAL_DK         = (PAL_D | PAL_D1 | PAL_K)

    #
    # "Common" PAL - This macro is there to be compatible with the old
    # V4L1 concept of "PAL": /BGDKHI.
    # Several PAL standards are missing here: /M, /N and /Nc
    #
    PAL            = (PAL_BG | PAL_DK | PAL_H | PAL_I)

    # Chroma "agnostic" standards
    B              = (PAL_B | PAL_B1 | SECAM_B)
    G              = (PAL_G | SECAM_G)
    H              = (PAL_H | SECAM_H)
    L              = (SECAM_L | SECAM_LC)
    GH             = (G | H)
    DK             = (PAL_DK |SECAM_DK)
    BG             = (B | G)
    MN             = (PAL_M | PAL_N | PAL_Nc | NTSC)

    # Standards where MTS/BTSC stereo could be found
    MTS            = (NTSC_M | PAL_M | PAL_N | PAL_Nc)

    # Standards for Countries with 60Hz Line frequency
    TV_525_60         = (PAL_M | PAL_60 | NTSC | NTSC_443)
    # Standards for Countries with 50Hz Line frequency */
    TV_625_50         = (PAL | PAL_N | PAL_Nc | SECAM)

    ATSC           = (ATSC_8_VSB | ATSC_16_VSB)

    # Macros with none and all analog standards
    UNKNOWN        = 0
    ALL            = (TV_525_60 | TV_625_50)
  end

  struct V4L2Standard
    index : U32
    id : V4L2StdID
    name : U8[24]
    frameperiod : V4L2Fract # Frames, not fields
    framelines : U32
    reserved : U32[4]
  end

  @[Packed]
  struct V4L2BTTimings
    width : U32
    height : U32
    interlaced : U32
    polarities : U32
    pixelclock : U64
    hfrontporch : U32
    hsync : U32
    hbackporch : U32
    vfrontporch : U32
    vsync : U32
    vbackporch : U32
    il_vfrontporch : U32
    il_vsync : U32
    il_vbackporch : U32
    standards : U32
    flags : U32
    picture_aspect : V4L2Fract
    cea861_vic : U8
    hdmi_vic : U8
    reserved : U8[46]
  end

  @[Flags]
  enum V4L2DVFlags
    #
    # CVT/GTF specific: timing uses reduced blanking (CVT) or the 'Secondary
    # GTF' curve (GTF). In both cases the horizontal and/or vertical blanking
    # intervals are reduced, allowing a higher resolution over the same
    # bandwidth. This is a read-only flag.
    #
    REDUCED_BLANKING = (1 << 0)
    
    #
    # CEA-861 specific: set for CEA-861 formats with a framerate of a multiple
    # of six. These formats can be optionally played at 1 / 1.001 speed.
    # This is a read-only flag.
    #
    CAN_REDUCE_FPS = (1 << 1)
    
    #
    # CEA-861 specific: only valid for video transmitters, the flag is cleared
    # by receivers.
    # If the framerate of the format is a multiple of six, then the pixelclock
    # used to set up the transmitter is divided by 1.001 to make it compatible
    # with 60 Hz based standards such as NTSC and PAL-M that use a framerate of
    # 29.97 Hz. Otherwise this flag is cleared. If the transmitter can't generate
    # such frequencies, then the flag will also be cleared.
    #
    REDUCED_FPS = (1 << 2)
    
    #
    # Specific to interlaced formats: if set, then field 1 is really one half-line
    # longer and field 2 is really one half-line shorter, so each field has
    # exactly the same number of half-lines. Whether half-lines can be detected
    # or used depends on the hardware.
    #
    HALF_LINE = (1 << 3)
    
    #
    # If set, then this is a Consumer Electronics (CE) video format. Such formats
    # differ from other formats (commonly called IT formats) in that if RGB
    # encoding is used then by default the RGB values use limited range (i.e.
    # use the range 16-235) as opposed to 0-255. All formats defined in CEA-861
    # except for the 640x480 format are CE formats.
    #
    IS_CE_VIDEO = (1 << 4)
    
    # Some formats like SMPTE-125M have an interlaced signal with a odd
    # total height. For these formats, if this flag is set, the first
    # field has the extra line. If not, it is the second field.
    #
    FIRST_FIELD_EXTRA_LINE = (1 << 5)
    
    #
    # If set, then the picture_aspect field is valid. Otherwise assume that the
    # pixels are square, so the picture aspect ratio is the same as the width to
    # height ratio.
    #
    HAS_PICTURE_ASPECT = (1 << 6)
    
    #
    # If set, then the cea861_vic field is valid and contains the Video
    # Identification Code as per the CEA-861 standard.
    #
    HAS_CEA861_VIC = (1 << 7)
    
    #
    # If set, then the hdmi_vic field is valid and contains the Video
    # Identification Code as per the HDMI standard (HDMI Vendor Specific
    # InfoFrame).
    #
    HAS_HDMI_VIC = (1 << 8)
    
    #
    # CEA-861 specific: only valid for video receivers.
    # If set, then HW can detect the difference between regular FPS and
    # 1000/1001 FPS. Note: This flag is only valid for HDMI VIC codes with
    # the CAN_REDUCE_FPS flag set.
    #
    CAN_DETECT_REDUCED_FPS = (1 << 9)
  end

  union V4L2DVTimingsUnion
    bt : V4L2BTTimings
    reserved : U32[32]
  end

  @[Packed]
  struct V4L2DVTimings
    type : U32
    union : V4L2DVTimingsUnion
  end

  V4L2_DV_BT_656_1120 = 0 # BT.656/1120 timing type

  struct V4L2EnumDVTimings
    index : U32
    pad : U32
    reserved : U32[2]
    timings : V4L2DVTimings
  end

  @[Packed]
  struct V4L2BTTimingsCap
    min_width : U32
    max_width : U32
    min_height : U32
    max_height : U32
    min_pixelclock : U64
    max_pixelclock : U64
    standards : U32
    capabilities : U32
    reserved : U32[16]
  end

  # Supports interlaced formats
  V4L2_DV_BT_CAP_INTERLACED = (1 << 0)

  # Supports progressive formats 
  V4L2_DV_BT_CAP_PROGRESSIVE = (1 << 1)

  # Supports CVT/GTF reduced blanking
  V4L2_DV_BT_CAP_REDUCED_BLANKING = (1 << 2)

  # Supports custom formats
  V4L2_DV_BT_CAP_CUSTOM = (1 << 3)

  union V4L2DVTimingsCapUnion
    bt : V4L2BTTimingsCap
    raw_data : U32[32]
  end

  struct V4L2DVTimingsCap
    type : U32
    pad : U32
    reserved : U32[2]
    union : V4L2DVTimingsCapUnion
  end

  struct V4L2Input
    index : U32
    name : U8[32]
    type : U32
    audioset : U32
    tuner : U32
    std : V4L2StdID
    status : U32
    capabilities : U32
    reserved : U32[3]
  end

  #
  # Values for the 'type' field
  #
  V4L2_INPUT_TYPE_TUNER  = 1
  V4L2_INPUT_TYPE_CAMERA = 2
  V4L2_INPUT_TYPE_TOUCH	 = 3

  #
  # field 'status' - general 
  #
  V4L2_IN_ST_NO_POWER  = 0x00000001  # Attached device is off
  V4L2_IN_ST_NO_SIGNAL = 0x00000002
  V4L2_IN_ST_NO_COLOR  = 0x00000004

  # field 'status' - sensor orientation
  # If sensor is mounted upside down set both bits
  V4L2_IN_ST_HFLIP = 0x00000010 # Frames are flipped horizontally
  V4L2_IN_ST_VFLIP = 0x00000020 # Frames are flipped vertically

  # field 'status' - analog
  V4L2_IN_ST_NO_H_LOCK   = 0x00000100  # No horizontal sync lock
  V4L2_IN_ST_COLOR_KILL  = 0x00000200  # Color killer is active
  V4L2_IN_ST_NO_V_LOCK   = 0x00000400  # No vertical sync lock
  V4L2_IN_ST_NO_STD_LOCK = 0x00000800  # No standard format lock

  # field 'status' - digital
  V4L2_IN_ST_NO_SYNC     = 0x00010000  # No synchronization lock
  V4L2_IN_ST_NO_EQU      = 0x00020000  # No equalizer lock
  V4L2_IN_ST_NO_CARRIER  = 0x00040000  # Carrier recovery failed

  # field 'status' - VCR and set-top box */
  V4L2_IN_ST_MACROVISION = 0x01000000  # Macrovision detected
  V4L2_IN_ST_NO_ACCESS   = 0x02000000  # Conditional access denied
  V4L2_IN_ST_VTR         = 0x04000000  # VTR time constant

  # capabilities flags
  V4L2_IN_CAP_DV_TIMINGS     = 0x00000002 # Supports S_DV_TIMINGS
  V4L2_IN_CAP_CUSTOM_TIMINGS = V4L2_IN_CAP_DV_TIMINGS # For compatibility
  V4L2_IN_CAP_STD            = 0x00000004 # Supports S_STD
  V4L2_IN_CAP_NATIVE_SIZE    = 0x00000008 # Supports setting native size

  struct V4L2Output
    index : U32        # Which output
    name : U8[32]      # Label
    type : U32         # Type of output
    audioset : U32     #  Associated audios (bitfield)
    modulator : U32    # Associated modulator
    std : V4L2StdID
    capabilities : U32
    rserved : U32[3]
  end

  #  Values for the 'type' field
  V4L2_OUTPUT_TYPE_MODULATOR        = 1
  V4L2_OUTPUT_TYPE_ANALOG           = 2
  V4L2_OUTPUT_TYPE_ANALOGVGAOVERLAY = 3

  # capabilities flags */
  V4L2_OUT_CAP_DV_TIMINGS     = 0x00000002 # Supports S_DV_TIMINGS
  V4L2_OUT_CAP_CUSTOM_TIMINGS	= V4L2_OUT_CAP_DV_TIMINGS # For compatibility
  V4L2_OUT_CAP_STD            = 0x00000004 # Supports S_STD
  V4L2_OUT_CAP_NATIVE_SIZE    = 0x00000008 # Supports setting native size

  struct V4L2Control
    id : U32
    value : S32
  end

  union V4L2ExtControlUnion
    value : S32
    value64 : S64
    p_u8 : U8 *
    p_u16 : U16 *
    p_u32 : U32 *
    ptr : Void *
  end

  struct V4L2ExtControl
    id : U32
    size : U32
    reserved2 : U32[1]
    union : V4L2ExtControlUnion
  end

  union V4L2ExtControlsUnion
    ctrl_class : U32
    which : U32
  end

  @[Packed]
  struct V4L2ExtControls
    union : V4L2ExtControlsUnion
    count : U32
    error_ids : U32
    request_fd : S32
    reserved : U32[1]
    controls : V4L2ExtControl *
  end

  V4L2_CTRL_ID_MASK           = 0x0fffffff
  V4L2_CTRL_MAX_DIMS          = 4
  V4L2_CTRL_WHICH_CUR_VAL     = 0
  V4L2_CTRL_WHICH_DEF_VAL     = 0x0f000000
  V4L2_CTRL_WHICH_REQUEST_VAL = 0x0f010000

  enum V4L2CtrlType : U32
    INTEGER      = 1
    BOOLEAN      = 2
    MENU         = 3
    BUTTON       = 4
    INTEGER64    = 5
    CTRL_CLASS   = 6
    STRING       = 7
    BITMASK      = 8
    INTEGER_MENU = 9

    # Compound types are >= 0x0100
    COMPOUND_TYPES = 0x0100
    U8             = 0x0100
    U16            = 0x0101
    U32            = 0x0102
  end

  # Used in the VIDIOC_QUERYCTRL ioctl for querying controls
  struct V4L2QueryCtrl
    id : U32
    type : V4L2CtrlType
    name : U8[32]       # Whatever
    minimum : S32       # Note signedness
    maximum : S32
    step : S32
    default_value : S32
    flags : U32
    reserved : U32[2]
  end

  # Used in the VIDIOC_QUERY_EXT_CTRL ioctl for querying extended controls
  struct V4L2QueryExtCtrl
    id : U32
    type : U32
    name : Char[32]
    minimum : S64
    maximum : S64
    step : U64
    default_value : S64
    flags : U32
    elem_size : U32
    elems : U32
    nr_of_dims : U32
    dims : U32[V4L2_CTRL_MAX_DIMS]
    reserved : U32[32]
  end

  struct V4L2QueryMenuUnion
    name : U8[32] # Whatever
    value : S64
  end

  # Used in the VIDIOC_QUERYMENU ioctl for querying menu items
  @[Packed]
  struct V4L2QueryMenu
    id : U32
    index : U32
    union : V4L2QueryMenuUnion
    reserved : U32
  end

  # Control flags
  V4L2_CTRL_FLAG_DISABLED         = 0x0001
  V4L2_CTRL_FLAG_GRABBED          = 0x0002
  V4L2_CTRL_FLAG_READ_ONLY        = 0x0004
  V4L2_CTRL_FLAG_UPDATE           = 0x0008
  V4L2_CTRL_FLAG_INACTIVE         = 0x0010
  V4L2_CTRL_FLAG_SLIDER           = 0x0020
  V4L2_CTRL_FLAG_WRITE_ONLY       = 0x0040
  V4L2_CTRL_FLAG_VOLATILE         = 0x0080
  V4L2_CTRL_FLAG_HAS_PAYLOAD      = 0x0100
  V4L2_CTRL_FLAG_EXECUTE_ON_WRITE = 0x0200
  V4L2_CTRL_FLAG_MODIFY_LAYOUT    = 0x0400

  # Query flags, to be ORed with the control ID
  V4L2_CTRL_FLAG_NEXT_CTRL     = 0x80000000
  V4L2_CTRL_FLAG_NEXT_COMPOUND = 0x40000000

  # User-class control IDs defined by V4L2
  V4L2_CID_MAX_CTRLS = 1024

  # IDs reserved for driver specific controls
  V4L2_CID_PRIVATE_BASE = 0x08000000

  struct V4L2Tuner
    index : U32
    name : U8[32]
    type : V4L2TunerType
    capability : V4L2TunerCap
    rangelow : U32
    rangehigh : U32
    rxsubchans : V4L2TunerSub
    audmode : V4L2TunerMode
    signal : S32
    afc : S32
    reserved : U32[4]
  end

  struct V4L2Modulator
    index : U32
    name : U8[32]
    capability : U32
    rangelow : U32
    rangehigh : U32
    txsubchans : U32
    type : V4L2TunerType
    reserved : U32[3]
  end

  #
  # Flags for the 'capability' field
  #
  @[Flags]
  enum V4L2TunerCap
    LOW             = 0x0001
    NORM            = 0x0002
    HWSEEK_BOUNDED  = 0x0004
    HWSEEK_WRAP     = 0x0008
    STEREO          = 0x0010
    LANG2           = 0x0020
    SAP             = 0x0020
    LANG1           = 0x0040
    RDS             = 0x0080
    RDS_BLOCK_IO    = 0x0100
    RDS_CONTROLS    = 0x0200
    FREQ_BANDS      = 0x0400
    HWSEEK_PROG_LIM = 0x0800
    FREQ_1HZ        = 0x1000
  end

  #
  # Flags for the 'rxsubchans' field
  #
  @[Flags]
  enum V4L2TunerSub
    MONO   = 0x0001
    STEREO = 0x0002
    LANG2  = 0x0004
    SAP    = 0x0004
    LANG1  = 0x0008
    RDS    = 0x0010
  end

  #
  # Values for the 'audmode' field
  #
  enum V4L2TunerMode : U32
    MONO        = 0x0000
    STEREO      = 0x0001
    LANG2       = 0x0002
    SAP         = 0x0002
    LANG1       = 0x0003
    LANG1_LANG2 = 0x0004
  end

  struct V4L2Frequency
    tuner : U32
    type : V4L2TunerType
    frequency : U32
    reserved : U32[8]
  end

  V4L2_BAND_MODULATION_VSB = (1 << 1)
  V4L2_BAND_MODULATION_FM  = (1 << 2)
  V4L2_BAND_MODULATION_AM  = (1 << 3)

  struct V4L2FrequencyBand
    tuner : U32
    type : V4L2TunerType
    index : U32
    capability : U32
    rangelow : U32
    rangehigh : U32
    mdulation : U32
    reserved : U32[9]
  end

  struct V4L2HWFreqSeek
    tuner : U32
    type : V4L2TunerType
    seek_upward : U32
    wrap_around : U32
    spacing : U32
    rangelow : U32
    rangehigh : U32
    reserved : U32[5]
  end

  #
  # RDS
  #
  @[Packed]
  struct V4L2RDSData
    lsb : U8
    msb : U8
    block : U8
  end

  V4L2_RDS_BLOCK_MSK     = 0x7
  V4L2_RDS_BLOCK_A       = 0
  V4L2_RDS_BLOCK_B       = 1
  V4L2_RDS_BLOCK_C       = 2
  V4L2_RDS_BLOCK_D       = 3
  V4L2_RDS_BLOCK_C_ALT   = 4
  V4L2_RDS_BLOCK_INVALID = 7

  V4L2_RDS_BLOCK_CORRECTED = 0x40
  V4L2_RDS_BLOCK_ERROR     = 0x80

  #
  # Audio
  #
  struct V4L2Audio
    index : U32
    name : U8[32]
    capability : U32
    mode : U32
    reserved : U32[2]
  end

  # Flags for the 'capability' field
  V4L2_AUDCAP_STEREO = 0x00001
  V4L2_AUDCAP_AVL	   = 0x00002

  # Flags for the 'mode' field */
  V4L2_AUDMODE_AVL = 0x00001

  struct V4L2AudioOut
    index : U32
    name : U8[32]
    capability : U32
    mode : U32
    reserved : U32[2]
  end

  #
  # MPEG Services
  #

  V4L2_ENC_IDX_FRAME_I    = 0
  V4L2_ENC_IDX_FRAME_P    = 1
  V4L2_ENC_IDX_FRAME_B    = 2
  V4L2_ENC_IDX_FRAME_MASK = 0xf

  struct V4L2EncIdxEntry
    offset : U64
    pts : U64
    length : U32
    flags : U32
    reserved : U32[2]
  end

  V4L2_ENC_IDX_ENTRIES = 64

  struct V4L2EncIdx
    entries : U32
    entries_cap : U32
    entry : V4L2EncIdxEntry[V4L2_ENC_IDX_ENTRIES]
  end

  V4L2_ENC_CMD_START  = 0
  V4L2_ENC_CMD_STOP   = 1
  V4L2_ENC_CMD_PAUSE  = 2
  V4L2_ENC_CMD_RESUME = 3

  # Flags for V4L2_ENC_CMD_STOP
  V4L2_ENC_CMD_STOP_AT_GOP_END = (1 << 0)

  struct V4L2EncoderCmdRaw
    data : U32[8]
  end

  union V4L2EncoderCmdUnion
    raw : V4L2EncoderCmdRaw
  end

  struct V4L2EncoderCmd
    cmd : U32
    flags : U32
    union : V4L2EncoderCmdUnion
  end

  # Decoder commands
  V4L2_DEC_CMD_START   = 0
  V4L2_DEC_CMD_STOP    = 1
  V4L2_DEC_CMD_PAUSE   = 2
  V4L2_DEC_CMD_RESUME  = 3

  # Flags for V4L2_DEC_CMD_START
  V4L2_DEC_CMD_START_MUTE_AUDIO = (1 << 0)

  # Flags for V4L2_DEC_CMD_PAUSE
  V4L2_DEC_CMD_PAUSE_TO_BLACK	= (1 << 0)

  # Flags for V4L2_DEC_CMD_STOP
  V4L2_DEC_CMD_STOP_TO_BLACK    = (1 << 0)
  V4L2_DEC_CMD_STOP_IMMEDIATELY = (1 << 1)

  # Play format requirements (returned by the driver):

  # The decoder has no special format requirements
  V4L2_DEC_START_FMT_NONE = 0
  # The decoder requires full GOPs
  V4L2_DEC_START_FMT_GOP  = 1

  struct V4L2DecoderCmdStop
    pts : U64
  end

  struct V4L2DecoderCmdStart
    # 0 or 1000 specifies normal speed,
    # 1 specifies forward single stepping,
    # -1 specifies backward single stepping,
    # >1: playback at speed/1000 of the normal speed,
    # <-1: reverse playback at (-speed/1000) of the normal speed.
    speed : S32
    format : U32
  end

  struct V4L2DecoderCmdRaw
    data : U32[16]
  end

  union V4L2DecoderCmdUnion
    stop : V4L2DecoderCmdStop
    start : V4L2DecoderCmdStart
    raw : V4L2DecoderCmdRaw
  end

  # The structure must be zeroed before use by the application
  # This ensures it can be extended safely in the future.
  struct V4L2DecoderCmd
    cmd : U32
    flags : U32
    union : V4L2DecoderCmdUnion
  end

  #
  # Data Services (VBI)
  #

  # Raw VBI
  struct V4L2VBIFormat
    sampling_rate : U32    # in 1 Hz
    offset : U32
    samples_per_line : U32
    sample_format : U32    # V4L2_PIX_FMT_
    start : S32[2]
    count : U32[2]
    flags : U32            # V4L2_VBI_
    reserved : U32[2]      # must be zero
  end

  # VBI flags
  V4L2_VBI_UNSYNC     = (1 << 0)
  V4L2_VBI_INTERLACED = (1 << 1)

  # ITU-R start lines for each field
  V4L2_VBI_ITU_525_F1_START = 1
  V4L2_VBI_ITU_525_F2_START = 264
  V4L2_VBI_ITU_625_F1_START = 1
  V4L2_VBI_ITU_625_F2_START = 314

  struct V4L2SlicedVBIFormat
    service_set : U16
    # service_lines[0][...] specifies lines 0-23 (1-23 used) of the first field
    # service_lines[1][...] specifies lines 0-23 (1-23 used) of the second field
    # (equals frame lines 313-336 for 625 line video standards, 263-286 for
    #  525 line standards)
    service_line_0 : U16[24] # HACK: multi-dimension array
    service_line_1 : U16[24] # HACK: multi-dimension array
    io_size : U32
    reserved : U32[2] # must be zero
  end

  # Teletext World System Teletext (WST), defined on ITU-R BT.653-2 
  V4L2_SLICED_TELETEXT_B = 0x0001
  # Video Program System, defined on ETS 300 231
  V4L2_SLICED_VPS = 0x0400
  # Closed Caption, defined on EIA-608
  V4L2_SLICED_CAPTION_525 = 0x1000
  # Wide Screen System, defined on ITU-R BT1119.1
  V4L2_SLICED_WSS_625 = 0x4000

  V4L2_SLICED_VBI_525 = V4L2_SLICED_CAPTION_525
  V4L2_SLICED_VBI_625 = (V4L2_SLICED_TELETEXT_B | V4L2_SLICED_VPS | V4L2_SLICED_WSS_625)

  struct V4L2SlicedVBICap
    service_set : U16
	  # service_lines[0][...] specifies lines 0-23 (1-23 used) of the first field
	  # service_lines[1][...] specifies lines 0-23 (1-23 used) of the second field
    # (equals frame lines 313-336 for 625 line video standards, 263-286 for
    #  525 line standards)
    service_lines : U16[2][24] # TODO: define multi-dimensional array
    type : V4L2BufType
    reserved : U32[3] # must be zero
  end

  struct V4L2SlicedVBIData
    iud : U32
    field : U32    # 0: first field, 1: second field
    line : U32     # 1-23
    reserved : U32
    data : U8[48]
  end

  #
  # Sliced VBI data inserted into MPEG Streams
  #

  # Line type IDs
  V4L2_MPEG_VBI_IVTV_TELETEXT_B  = 1
  V4L2_MPEG_VBI_IVTV_CAPTION_525 = 4
  V4L2_MPEG_VBI_IVTV_WSS_625     = 5
  V4L2_MPEG_VBI_IVTV_VPS         = 7

  @[Packed]
  struct V4L2MPEGVBIITV0Line
    id : U8       # One of V4L2_MPEG_VBI_IVTV_* above
    data : U8[42] # Sliced VBI data for the line
  end

  @[Packed]
  struct V4L2MPEGVBI_itv0
    linemask : U32[2] # Bitmasks of VBI service lines present
    line : V4L2MPEGVBIITV0Line[35]
  end

  @[Packed]
  struct V4L2MPEGVBI_ITV0
    line : V4L2MPEGVBIITV0Line[36]
  end

  V4L2_MPEG_VBI_IVTV_MAGIC0 = "itv0"
  V4L2_MPEG_VBI_IVTV_MAGIC1 = "ITV0"

  @[Packed]
  union V4L2MPEGVBIFmtIVTVUnion
    _itv0 : V4L2MPEGVBI_itv0
    _ITV0 : V4L2MPEGVBI_ITV0
  end

  @[Packed]
  struct V4L2MPEGVBIFmtIVTV
    magic : U8[4]
    union : V4L2MPEGVBIFmtIVTVUnion
  end

  #
  # AGGREGATE STRUCTURES
  #

  @[Packed]
  struct V4L2PlanePixFormat
    sizeimage : U32
    bytesperline : U32
    reserved : U16[6]
  end

  @[Packed]
  union V4L2PixFormatMPlaneUnion
    ycbcr_enc : U8
    hsv_enc : U8
  end

  @[Packed]
  struct V4L2PixFormatMPlane
    width : U32
    height : U32
    pixelformat : U32
    field : U32
    colorspace : U32
    plane_fmt : V4L2PlanePixFormat[VIDEO_MAX_PLANES]
    num_planes : U8
    flags : U8
    union : V4L2PixFormatMPlaneUnion
    quantization : U8
    xfer_func : U8
    reserved : U8[7]
  end

  @[Packed]
  struct V4L2SDRFormat
    pixelformat : U32
    buffersize : U32
    reserved : U8[24]
  end

  @[Packed]
  struct V4L2MetaFormat
    dataformat : U32
    buffersize : U32
  end

  union V4L2FormatUnion
    pix : V4L2PixFormat          # V4L2_BUF_TYPE_VIDEO_CAPTURE
    pix_mp : V4L2PixFormatMPlane # V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE
    win : V4L2Window             # V4L2_BUF_TYPE_VIDEO_OVERLAY
    vbi : V4L2VBIFormat          # V4L2_BUF_TYPE_VBI_CAPTURE
    sliced : V4L2SlicedVBIFormat # V4L2_BUF_TYPE_SLICED_VBI_CAPTURE
    sdr : V4L2SDRFormat          # V4L2_BUF_TYPE_SDR_CAPTURE
    meta : V4L2MetaFormat        # V4L2_BUF_TYPE_META_CAPTURE
    raw_data : U8[200]           # user-defined
  end

  struct V4L2Format
    type : U32
    fmt : V4L2FormatUnion
  end

  union V4L2StreamParmUnion
    capture : V4L2CaptureParm
    output : V4L2OutputParm
    raw_data : U8[200]         # user-defined
  end

  struct V4L2StreamParm
    tyep : V4L2BufType
    parm : V4L2StreamParmUnion
  end

  #
  # EVENTS
  #

  V4L2_EVENT_ALL            = 0
  V4L2_EVENT_VSYNC          = 1
  V4L2_EVENT_EOS            = 2
  V4L2_EVENT_CTRL           = 3
  V4L2_EVENT_FRAME_SYNC     = 4
  V4L2_EVENT_SOURCE_CHANGE  = 5
  V4L2_EVENT_MOTION_DET     = 6
  V4L2_EVENT_PRIVATE_START  = 0x08000000

  # Payload for V4L2_EVENT_VSYNC
  @[Packed]
  struct V4L2EventVSync
	  # Can be V4L2_FIELD_ANY, _NONE, _TOP or _BOTTOM
    field : U8
  end

  # Payload for V4L2_EVENT_CTRL
  V4L2_EVENT_CTRL_CH_VALUE = (1 << 0)
  V4L2_EVENT_CTRL_CH_FLAGS = (1 << 1)
  V4L2_EVENT_CTRL_CH_RANGE = (1 << 2)

  union V4L2EventCtrlUnion
    value : S32
    value64 : S64
  end

  struct V4L2EventCtrl
    changes : U32
    type : U32
    union : V4L2EventCtrlUnion
    flags : U32
    minimum : S32
    maximum : S32
    step : S32
    default_value : S32
  end

  struct V4L2EventFrameSync
    frame_sequence : U32
  end

  V4L2_EVENT_SRC_CH_RESOLUTION = (1 << 0)

  struct V4L2EventSrcChange
    change : U32
  end

  V4L2_EVENT_MD_FL_HAVE_FRAME_SEQ = (1 << 0)

  struct V4L2EventMotionDet
    flags : U32
    frame_sequences : U32
    region_mask : U32
  end

  struct V4L2EventUnion
    vsync : V4L2EventVSync
    ctrl : V4L2EventCtrl
    frame_sync : V4L2EventFrameSync
    src_change : V4L2EventSrcChange
    motion_det : V4L2EventMotionDet
    data : U8[64]
  end

  struct V4L2Event
    type : U32
    union : V4L2EventUnion
    pending : U32
    sequence : U32
    timestamp : LibC::Timespec
    id : U32
    reserved : U32[8]
  end

  V4L2_EVENT_SUB_FL_SEND_INITIAL   = (1 << 0)
  V4L2_EVENT_SUB_FL_ALLOW_FEEDBACK = (1 << 1)

  struct V4L2EventSubscription
    type : U32
    id : U32
    flags : U32
    reserved : U32[5]
  end

  #
  # ADVANCED DEBUGGING
  #

  # VIDIOC_DBG_G_REGISTER and VIDIOC_DBG_S_REGISTER
  V4L2_CHIP_MATCH_BRIDGE      = 0  # Match against chip ID on the bridge (0 for the bridge)
  V4L2_CHIP_MATCH_SUBDEV      = 4  # Match against subdev index

  # The following four defines are no longer in use
  V4L2_CHIP_MATCH_HOST        = V4L2_CHIP_MATCH_BRIDGE
  V4L2_CHIP_MATCH_I2C_DRIVER  = 1  # Match against I2C driver name
  V4L2_CHIP_MATCH_I2C_ADDR    = 2  # Match against I2C 7-bit address
  V4L2_CHIP_MATCH_AC97        = 3  # Match against ancillary AC97 chip

  @[Packed]
  union V4L2DbgMatchUnion
    addr : U32
    name : Char[32]
  end

  @[Packed]
  struct V4L2DbgMatch
    type : U32                # Match type
    union : V4L2DbgMatchUnion # Match this chip, meaning determined by type
  end

  @[Packed]
  struct V4L2DbgRegister
    match : V4L2DbgMatch
    size : U32 # register size in bytes
    reg : U64
    val : U64
  end

  V4L2_CHIP_FL_READABLE = (1 << 0)
  V4L2_CHIP_FL_WRITABLE = (1 << 1)

  # VIDIOC_DBG_G_CHIP_INFO
  @[Packed]
  struct V4L2DbgChipInfo
    match : V4L2DbgMatch
    name : Char[32]
    flags : U32
    reserved : U32[32]
  end

  struct V4L2CreateBuffers
    index : U32
    count : U32
    memory : U32
    format : V4L2Format
    capabilities : U32
    reserved : U32[7]
  end

  #
  # IOCTL CODES FOR VIDEO DEVICES
  #
  VIDIOC_QUERYCAP		         = ioctl_ior('V', 0, V4L2Capability)
  VIDIOC_ENUM_FMT            = ioctl_iowr('V', 2, V4L2FmtDesc)
  VIDIOC_G_FMT		           = ioctl_iowr('V',  4, V4L2Format)
  VIDIOC_S_FMT		           = ioctl_iowr('V',  5, V4L2Format)
  VIDIOC_REQBUFS		         = ioctl_iowr('V',  8, V4L2RequestBuffers)
  VIDIOC_QUERYBUF		         = ioctl_iowr('V',  9, V4L2Buffer)
  VIDIOC_G_FBUF		           = ioctl_ior('V', 10, V4L2FrameBuffer)
  VIDIOC_S_FBUF		           = ioctl_iow('V', 11, V4L2FrameBuffer)
  VIDIOC_OVERLAY		         = ioctl_iow('V', 14, Int)
  VIDIOC_QBUF		             = ioctl_iowr('V', 15, V4L2Buffer)
  VIDIOC_EXPBUF		           = ioctl_iowr('V', 16, V4L2ExportBuffer)
  VIDIOC_DQBUF		           = ioctl_iowr('V', 17, V4L2Buffer)
  VIDIOC_STREAMON		         = ioctl_iow('V', 18, Int)
  VIDIOC_STREAMOFF	         = ioctl_iow('V', 19, Int)
  VIDIOC_G_PARM		           = ioctl_iowr('V', 21, V4L2StreamParm)
  VIDIOC_S_PARM		           = ioctl_iowr('V', 22, V4L2StreamParm)
  VIDIOC_G_STD		           = ioctl_ior('V', 23, V4L2StdID)
  VIDIOC_S_STD		           = ioctl_iow('V', 24, V4L2StdID)
  VIDIOC_ENUMSTD		         = ioctl_iowr('V', 25, V4L2Standard)
  VIDIOC_ENUMINPUT	         = ioctl_iowr('V', 26, V4L2Input)
  VIDIOC_G_CTRL		           = ioctl_iowr('V', 27, V4L2Control)
  VIDIOC_S_CTRL		           = ioctl_iowr('V', 28, V4L2Control)
  VIDIOC_G_TUNER		         = ioctl_iowr('V', 29, V4L2Tuner)
  VIDIOC_S_TUNER		         = ioctl_iow('V', 30, V4L2Tuner)
  VIDIOC_G_AUDIO		         = ioctl_ior('V', 33, V4L2Audio)
  VIDIOC_S_AUDIO		         = ioctl_iow('V', 34, V4L2Audio)
  VIDIOC_QUERYCTRL	         = ioctl_iowr('V', 36, V4L2QueryCtrl)
  VIDIOC_QUERYMENU	         = ioctl_iowr('V', 37, V4L2QueryMenu)
  VIDIOC_G_INPUT		         = ioctl_ior('V', 38, Int)
  VIDIOC_S_INPUT		         = ioctl_iowr('V', 39, Int)
  VIDIOC_G_EDID		           = ioctl_iowr('V', 40, V4L2EDID)
  VIDIOC_S_EDID		           = ioctl_iowr('V', 41, V4L2EDID)
  VIDIOC_G_OUTPUT		         = ioctl_ior('V', 46, Int)
  VIDIOC_S_OUTPUT		         = ioctl_iowr('V', 47, Int)
  VIDIOC_ENUMOUTPUT	         = ioctl_iowr('V', 48, V4L2Output)
  VIDIOC_G_AUDOUT		         = ioctl_ior('V', 49, V4L2AudioOut)
  VIDIOC_S_AUDOUT		         = ioctl_iow('V', 50, V4L2AudioOut)
  VIDIOC_G_MODULATOR	       = ioctl_iowr('V', 54, V4L2Modulator)
  VIDIOC_S_MODULATOR	       = ioctl_iow('V', 55, V4L2Modulator)
  VIDIOC_G_FREQUENCY	       = ioctl_iowr('V', 56, V4L2Frequency)
  VIDIOC_S_FREQUENCY	       = ioctl_iow('V', 57, V4L2Frequency)
  VIDIOC_CROPCAP		         = ioctl_iowr('V', 58, V4L2CropCap)
  VIDIOC_G_CROP		           = ioctl_iowr('V', 59, V4L2Crop)
  VIDIOC_S_CROP		           = ioctl_iow('V', 60, V4L2Crop)
  VIDIOC_G_JPEGCOMP	         = ioctl_ior('V', 61, V4L2JPEGCompression)
  VIDIOC_S_JPEGCOMP	         = ioctl_iow('V', 62, V4L2JPEGCompression)
  VIDIOC_QUERYSTD		         = ioctl_ior('V', 63, V4L2StdID)
  VIDIOC_TRY_FMT		         = ioctl_iowr('V', 64, V4L2Format)
  VIDIOC_ENUMAUDIO	         = ioctl_iowr('V', 65, V4L2Audio)
  VIDIOC_ENUMAUDOUT	         = ioctl_iowr('V', 66, V4L2AudioOut)
  VIDIOC_G_PRIORITY	         = ioctl_ior('V', 67, V4L2Priority)
  VIDIOC_S_PRIORITY	         = ioctl_iow('V', 68, V4L2Priority)
  VIDIOC_G_SLICED_VBI_CAP    = ioctl_iowr('V', 69, V4L2SlicedVBICap)
  VIDIOC_LOG_STATUS          = ioctl_io('V', 70)
  VIDIOC_G_EXT_CTRLS	       = ioctl_iowr('V', 71, V4L2ExtControls)
  VIDIOC_S_EXT_CTRLS	       = ioctl_iowr('V', 72, V4L2ExtControls)
  VIDIOC_TRY_EXT_CTRLS	     = ioctl_iowr('V', 73, V4L2ExtControls)
  VIDIOC_ENUM_FRAMESIZES	   = ioctl_iowr('V', 74, V4L2FrmSizeEnum)
  VIDIOC_ENUM_FRAMEINTERVALS = ioctl_iowr('V', 75, V4L2FrmIvalEnum)
  VIDIOC_G_ENC_INDEX         = ioctl_ior('V', 76, V4L2EncIdx)
  VIDIOC_ENCODER_CMD         = ioctl_iowr('V', 77, V4L2EncoderCmd)
  VIDIOC_TRY_ENCODER_CMD     = ioctl_iowr('V', 78, V4L2EncoderCmd)

  #
  # Experimental, meant for debugging, testing and internal use.
  # Only implemented if CONFIG_VIDEO_ADV_DEBUG is defined.
  # You must be root to use these ioctls. Never use these in applications!
  #
  VIDIOC_DBG_S_REGISTER = ioctl_iow('V', 79, V4L2DbgRegister)
  VIDIOC_DBG_G_REGISTER = ioctl_iowr('V', 80, V4L2Dbg_register)

  VIDIOC_S_HW_FREQ_SEEK    = ioctl_iow('V', 82, V4L2HWFreqSeek)
  VIDIOC_S_DV_TIMINGS      = ioctl_iowr('V', 87, V4L2DVTimings)
  VIDIOC_G_DV_TIMINGS      = ioctl_iowr('V', 88, V4L2DVTimings)
  VIDIOC_DQEVENT           = ioctl_ior('V', 89, V4L2Event)
  VIDIOC_SUBSCRIBE_EVENT   = ioctl_iow('V', 90, V4L2EventSubscription)
  VIDIOC_UNSUBSCRIBE_EVENT = ioctl_iow('V', 91, V4L2EventSubscription)
  VIDIOC_CREATE_BUFS       = ioctl_iowr('V', 92, V4L2CreateBuffers)
  VIDIOC_PREPARE_BUF       = ioctl_iowr('V', 93, V4L2Buffer)
  VIDIOC_G_SELECTION       = ioctl_iowr('V', 94, V4L2Selection)
  VIDIOC_S_SELECTION       = ioctl_iowr('V', 95, V4L2Selection)
  VIDIOC_DECODER_CMD       = ioctl_iowr('V', 96, V4L2DecoderCmd)
  VIDIOC_TRY_DECODER_CMD   = ioctl_iowr('V', 97, V4L2DecoderCmd)
  VIDIOC_ENUM_DV_TIMINGS   = ioctl_iowr('V', 98, V4L2EnumDVTimings)
  VIDIOC_QUERY_DV_TIMINGS  = ioctl_ior('V', 99, V4L2DVTimings)
  VIDIOC_DV_TIMINGS_CAP    = ioctl_iowr('V', 100, V4L2DVTimingsCap)
  VIDIOC_ENUM_FREQ_BANDS   = ioctl_iowr('V', 101, V4L2FrequencyBand)

  #
  # Experimental, meant for debugging, testing and internal use.
  # Never use this in applications!
  #
  VIDIOC_DBG_G_CHIP_INFO = ioctl_iowr('V', 102, V4L2DbgChipInfo)

  VIDIOC_QUERY_EXT_CTRL	= ioctl_iowr('V', 103, V4L2QueryExtCtrl)

  # Reminder: when adding new ioctls please add support for them to
  # drivers/media/v4l2-core/v4l2-compat-ioctl32.c as well!

  BASE_VIDIOC_PRIVATE = 192 # 192-255 are private
end

module V4L2
  @[AlwaysInline]
  def self.timeval_to_ns(tv : LibC::TimeVal *) : UInt64
    tv.tv_sec * 1000000000_u64 + tv.tv_usec * 1000
  end
end
