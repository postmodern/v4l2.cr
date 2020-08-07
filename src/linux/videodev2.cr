require "./types"
require "./v4l2-common"
require "./v4l2-controls"

# Four-character-code (FOURCC)
macro v4l2_fourcc(a,b,c,d)
  {% 
    # HACK: because CharLiteral#ord doesn't exist yet
    ascii_table = {
      ' ' => 32_u8,
      '0' => 48_u8,
      '1' => 49_u8,
      '2' => 50_u8,
      '3' => 51_u8,
      '4' => 52_u8,
      '5' => 53_u8,
      '6' => 54_u8,
      '7' => 55_u8,
      '8' => 56_u8,
      '9' => 57_u8,
      'A' => 65_u8,
      'B' => 66_u8,
      'C' => 67_u8,
      'D' => 68_u8,
      'E' => 69_u8,
      'F' => 70_u8,
      'G' => 71_u8,
      'H' => 72_u8,
      'I' => 73_u8,
      'J' => 74_u8,
      'K' => 75_u8,
      'L' => 76_u8,
      'M' => 77_u8,
      'N' => 78_u8,
      'O' => 79_u8,
      'P' => 80_u8,
      'Q' => 81_u8,
      'R' => 82_u8,
      'S' => 83_u8,
      'T' => 84_u8,
      'U' => 85_u8,
      'V' => 86_u8,
      'W' => 87_u8,
      'X' => 88_u8,
      'Y' => 89_u8,
      'Z' => 90_u8,
      'a' => 97_u8,
      'b' => 98_u8,
      'c' => 99_u8,
      'd' => 100_u8,
      'e' => 101_u8,
      'f' => 102_u8,
      'g' => 103_u8,
      'h' => 104_u8,
      'i' => 105_u8,
      'j' => 106_u8,
      'k' => 107_u8,
      'l' => 108_u8,
      'm' => 109_u8,
      'n' => 110_u8,
      'o' => 111_u8,
      'p' => 112_u8,
      'q' => 113_u8,
      'r' => 114_u8,
      's' => 115_u8,
      't' => 116_u8,
      'u' => 117_u8,
      'v' => 118_u8,
      'w' => 119_u8,
      'x' => 120_u8,
      'y' => 121_u8,
      'z' => 122_u8,
    } 
  %}

  {% begin %}
  {{ (ascii_table[a] | (ascii_table[b] << 8) | (ascii_table[c] << 16) | (ascii_table[d] << 24)) }}
  {% end %}
end

macro v4l2_fourcc_be(a,b,c,d)
  v4l2_fourcc({{ a }}, {{ b }}, {{ c }}, {{ d }}) | (1_u32 << 31)
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

  enum V4L2Field : U32
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

  enum V4L2Memory : U32
    MMAP             = 1
    USER_PTR         = 2
    OVERLAY          = 3
    DMA_BUF          = 4
  end

  # see also http://vektor.theorem.ca/graphics/ycbcr/
  enum V4L2ColorSpace : U32
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

  enum V4L2XFERFunc : U32
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

  enum V4L2Quantization : U32
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
    pixelformat : V4L2PixFmt
    field : V4L2Field
    bytesperline : U32   # for padding, zero if unused
    sizeimage : U32
    colorspace : V4L2ColorSpace
    priv : U32           # private data, depends on pixelformat
    flags : U32          # format flags (V4L2_PIX_FMT_FLAG_*)
    enc : V4L2PixFormatEnc
    quality : V4L2Quantization
    xfer_func : V4L2XFERFunc
  end
end

#
# HACK: must define the enums outside of lib Linux because of
#       https://github.com/crystal-lang/crystal/issues/8855
#
enum Linux::V4L2PixFmt : Linux::U32
  #
  # RGB formats
  #
  RGB332  = v4l2_fourcc('R', 'G', 'B', '1') #  8  RGB-3-3-2
  RGB444  = v4l2_fourcc('R', '4', '4', '4') # 16  xxxxrrrr ggggbbbb
  ARGB444 = v4l2_fourcc('A', 'R', '1', '2') # 16  aaaarrrr ggggbbbb
  XRGB444 = v4l2_fourcc('X', 'R', '1', '2') # 16  xxxxrrrr ggggbbbb
  RGBA444 = v4l2_fourcc('R', 'A', '1', '2') # 16  rrrrgggg bbbbaaaa
  RGBX444 = v4l2_fourcc('R', 'X', '1', '2') # 16  rrrrgggg bbbbxxxx
  ABGR444 = v4l2_fourcc('A', 'B', '1', '2') # 16  aaaabbbb ggggrrrr
  XBGR444 = v4l2_fourcc('X', 'B', '1', '2') # 16  xxxxbbbb ggggrrrr

  #
  # Originally this had 'BA12' as fourcc, but this clashed with the older
  # V4L2_PIX_FMT_SGRBG12 which inexplicably used that same fourcc.
  # So use 'GA12' instead for V4L2_PIX_FMT_BGRA444.
  #
  BGRA444  = v4l2_fourcc('G', 'A', '1', '2') # 16  bbbbgggg rrrraaaa
  BGRX444  = v4l2_fourcc('B', 'X', '1', '2') # 16  bbbbgggg rrrrxxxx
  RGB555   = v4l2_fourcc('R', 'G', 'B', 'O') # 16  RGB-5-5-5
  ARGB555  = v4l2_fourcc('A', 'R', '1', '5') # 16  ARGB-1-5-5-5
  XRGB555  = v4l2_fourcc('X', 'R', '1', '5') # 16  XRGB-1-5-5-5
  RGBA555  = v4l2_fourcc('R', 'A', '1', '5') # 16  RGBA-5-5-5-1
  RGBX555  = v4l2_fourcc('R', 'X', '1', '5') # 16  RGBX-5-5-5-1
  ABGR555  = v4l2_fourcc('A', 'B', '1', '5') # 16  ABGR-1-5-5-5
  XBGR555  = v4l2_fourcc('X', 'B', '1', '5') # 16  XBGR-1-5-5-5
  BGRA555  = v4l2_fourcc('B', 'A', '1', '5') # 16  BGRA-5-5-5-1
  BGRX555  = v4l2_fourcc('B', 'X', '1', '5') # 16  BGRX-5-5-5-1
  RGB565   = v4l2_fourcc('R', 'G', 'B', 'P') # 16  RGB-5-6-5
  RGB555X  = v4l2_fourcc('R', 'G', 'B', 'Q') # 16  RGB-5-5-5 BE
  ARGB555X = v4l2_fourcc_be('A', 'R', '1', '5') # 16  ARGB-5-5-5 BE
  XRGB555X = v4l2_fourcc_be('X', 'R', '1', '5') # 16  XRGB-5-5-5 BE
  RGB565X  = v4l2_fourcc('R', 'G', 'B', 'R') # 16  RGB-5-6-5 BE
  BGR666   = v4l2_fourcc('B', 'G', 'R', 'H') # 18  BGR-6-6-6
  BGR24    = v4l2_fourcc('B', 'G', 'R', '3') # 24  BGR-8-8-8
  RGB24    = v4l2_fourcc('R', 'G', 'B', '3') # 24  RGB-8-8-8
  BGR32    = v4l2_fourcc('B', 'G', 'R', '4') # 32  BGR-8-8-8-8
  ABGR32   = v4l2_fourcc('A', 'R', '2', '4') # 32  BGRA-8-8-8-8
  XBGR32   = v4l2_fourcc('X', 'R', '2', '4') # 32  BGRX-8-8-8-8
  BGRA32   = v4l2_fourcc('R', 'A', '2', '4') # 32  ABGR-8-8-8-8
  BGRX32   = v4l2_fourcc('R', 'X', '2', '4') # 32  XBGR-8-8-8-8
  RGB32    = v4l2_fourcc('R', 'G', 'B', '4') # 32  RGB-8-8-8-8
  RGBA32   = v4l2_fourcc('A', 'B', '2', '4') # 32  RGBA-8-8-8-8
  RGBX32   = v4l2_fourcc('X', 'B', '2', '4') # 32  RGBX-8-8-8-8
  ARGB32   = v4l2_fourcc('B', 'A', '2', '4') # 32  ARGB-8-8-8-8
  XRGB32   = v4l2_fourcc('B', 'X', '2', '4') # 32  XRGB-8-8-8-8

  #
  # Grey formats
  #
  GREY   = v4l2_fourcc('G', 'R', 'E', 'Y') #  8  Greyscale
  Y4     = v4l2_fourcc('Y', '0', '4', ' ') #  4  Greyscale
  Y6     = v4l2_fourcc('Y', '0', '6', ' ') #  6  Greyscale
  Y10    = v4l2_fourcc('Y', '1', '0', ' ') # 10  Greyscale
  Y12    = v4l2_fourcc('Y', '1', '2', ' ') # 12  Greyscale
  Y16    = v4l2_fourcc('Y', '1', '6', ' ') # 16  Greyscale
  Y16_BE = v4l2_fourcc_be('Y', '1', '6', ' ') # 16  Greyscale BE

  #
  # Grey bit-packed formats
  #
  Y10BPACK = v4l2_fourcc('Y', '1', '0', 'B') # 10  Greyscale bit-packed
  Y10P     = v4l2_fourcc('Y', '1', '0', 'P') # 10  Greyscale, MIPI RAW10 packed

  #
  # Palette formats
  #
  PAL8 = v4l2_fourcc('P', 'A', 'L', '8') #  8  8-bit palette

  #
  # Chrominance formats
  #
  UV8 = v4l2_fourcc('U', 'V', '8', ' ') #  8  UV 4:4

  #
  # Luminance+Chrominance formats
  #
  YUYV   = v4l2_fourcc('Y', 'U', 'Y', 'V') # 16  YUV 4:2:2
  YYUV   = v4l2_fourcc('Y', 'Y', 'U', 'V') # 16  YUV 4:2:2
  YVYU   = v4l2_fourcc('Y', 'V', 'Y', 'U') # 16 YVU 4:2:2
  UYVY   = v4l2_fourcc('U', 'Y', 'V', 'Y') # 16  YUV 4:2:2
  VYUY   = v4l2_fourcc('V', 'Y', 'U', 'Y') # 16  YUV 4:2:2
  Y41P   = v4l2_fourcc('Y', '4', '1', 'P') # 12  YUV 4:1:1
  YUV444 = v4l2_fourcc('Y', '4', '4', '4') # 16  xxxxyyyy uuuuvvvv
  YUV555 = v4l2_fourcc('Y', 'U', 'V', 'O') # 16  YUV-5-5-5
  YUV565 = v4l2_fourcc('Y', 'U', 'V', 'P') # 16  YUV-5-6-5
  YUV32  = v4l2_fourcc('Y', 'U', 'V', '4') # 32  YUV-8-8-8-8
  AYUV32 = v4l2_fourcc('A', 'Y', 'U', 'V') # 32  AYUV-8-8-8-8
  XYUV32 = v4l2_fourcc('X', 'Y', 'U', 'V') # 32  XYUV-8-8-8-8
  VUYA32 = v4l2_fourcc('V', 'U', 'Y', 'A') # 32  VUYA-8-8-8-8
  VUYX32 = v4l2_fourcc('V', 'U', 'Y', 'X') # 32  VUYX-8-8-8-8
  HI240  = v4l2_fourcc('H', 'I', '2', '4') #  8  8-bit color
  HM12   = v4l2_fourcc('H', 'M', '1', '2') #  8  YUV 4:2:0 16x16 macroblocks
  M420   = v4l2_fourcc('M', '4', '2', '0') # 12  YUV 4:2:0 2 lines y, 1 line uv interleaved

  #
  # two planes -- one Y, one Cr + Cb interleaved
  #
  NV12 = v4l2_fourcc('N', 'V', '1', '2') # 12  Y/CbCr 4:2:0
  NV21 = v4l2_fourcc('N', 'V', '2', '1') # 12  Y/CrCb 4:2:0
  NV16 = v4l2_fourcc('N', 'V', '1', '6') # 16  Y/CbCr 4:2:2
  NV61 = v4l2_fourcc('N', 'V', '6', '1') # 16  Y/CrCb 4:2:2
  NV24 = v4l2_fourcc('N', 'V', '2', '4') # 24  Y/CbCr 4:4:4
  NV42 = v4l2_fourcc('N', 'V', '4', '2') # 24  Y/CrCb 4:4:4

  #
  # two non contiguous planes - one Y, one Cr + Cb interleaved
  #
  NV12M        = v4l2_fourcc('N', 'M', '1', '2') # 12  Y/CbCr 4:2:0
  NV21M        = v4l2_fourcc('N', 'M', '2', '1') # 21  Y/CrCb 4:2:0
  NV16M        = v4l2_fourcc('N', 'M', '1', '6') # 16  Y/CbCr 4:2:2
  NV61M        = v4l2_fourcc('N', 'M', '6', '1') # 16  Y/CrCb 4:2:2
  NV12MT       = v4l2_fourcc('T', 'M', '1', '2') # 12  Y/CbCr 4:2:0 64x32 macroblocks
  NV12MT_16X16 = v4l2_fourcc('V', 'M', '1', '2') # 12  Y/CbCr 4:2:0 16x16 macroblocks

  #
  # three planes - Y Cb, Cr
  #
  YUV410  = v4l2_fourcc('Y', 'U', 'V', '9') #  9  YUV 4:1:0
  YVU410  = v4l2_fourcc('Y', 'V', 'U', '9') #  9  YVU 4:1:0
  YUV411P = v4l2_fourcc('4', '1', '1', 'P') # 12  YVU411 planar
  YUV420  = v4l2_fourcc('Y', 'U', '1', '2') # 12  YUV 4:2:0
  YVU420  = v4l2_fourcc('Y', 'V', '1', '2') # 12  YVU 4:2:0
  YUV422P = v4l2_fourcc('4', '2', '2', 'P') # 16  YVU422 planar

  #
  # three non contiguous planes - Y, Cb, Cr
  #
  YUV420M = v4l2_fourcc('Y', 'M', '1', '2') # 12  YUV420 planar
  YVU420M = v4l2_fourcc('Y', 'M', '2', '1') # 12  YVU420 planar
  YUV422M = v4l2_fourcc('Y', 'M', '1', '6') # 16  YUV422 planar
  YVU422M = v4l2_fourcc('Y', 'M', '6', '1') # 16  YVU422 planar
  YUV444M = v4l2_fourcc('Y', 'M', '2', '4') # 24  YUV444 planar
  YVU444M = v4l2_fourcc('Y', 'M', '4', '2') # 24  YVU444 planar

  #
  # Bayer formats - see http://www.siliconimaging.com/RGB%20Bayer.htm
  #
  SBGGR8  = v4l2_fourcc('B', 'A', '8', '1') #  8  BGBG.. GRGR..
  SGBRG8  = v4l2_fourcc('G', 'B', 'R', 'G') #  8  GBGB.. RGRG..
  SGRBG8  = v4l2_fourcc('G', 'R', 'B', 'G') #  8  GRGR.. BGBG..
  SRGGB8  = v4l2_fourcc('R', 'G', 'G', 'B') #  8  RGRG.. GBGB..
  SBGGR10 = v4l2_fourcc('B', 'G', '1', '0') # 10  BGBG.. GRGR..
  SGBRG10 = v4l2_fourcc('G', 'B', '1', '0') # 10  GBGB.. RGRG..
  SGRBG10 = v4l2_fourcc('B', 'A', '1', '0') # 10  GRGR.. BGBG..
  SRGGB10 = v4l2_fourcc('R', 'G', '1', '0') # 10  RGRG.. GBGB..
  # 10bit raw bayer packed, 5 bytes for every 4 pixels
  SBGGR10P = v4l2_fourcc('p', 'B', 'A', 'A')
  SGBRG10P = v4l2_fourcc('p', 'G', 'A', 'A')
  SGRBG10P = v4l2_fourcc('p', 'g', 'A', 'A')
  SRGGB10P = v4l2_fourcc('p', 'R', 'A', 'A')
  # 10bit raw bayer a-law compressed to 8 bits
  SBGGR10ALAW8 = v4l2_fourcc('a', 'B', 'A', '8')
  SGBRG10ALAW8 = v4l2_fourcc('a', 'G', 'A', '8')
  SGRBG10ALAW8 = v4l2_fourcc('a', 'g', 'A', '8')
  SRGGB10ALAW8 = v4l2_fourcc('a', 'R', 'A', '8')
  # 10bit raw bayer DPCM compressed to 8 bits
  SBGGR10DPCM8 = v4l2_fourcc('b', 'B', 'A', '8')
  SGBRG10DPCM8 = v4l2_fourcc('b', 'G', 'A', '8')
  SGRBG10DPCM8 = v4l2_fourcc('B', 'D', '1', '0')
  SRGGB10DPCM8 = v4l2_fourcc('b', 'R', 'A', '8')
  SBGGR12 = v4l2_fourcc('B', 'G', '1', '2') # 12  BGBG.. GRGR..
  SGBRG12 = v4l2_fourcc('G', 'B', '1', '2') # 12  GBGB.. RGRG..
  SGRBG12 = v4l2_fourcc('B', 'A', '1', '2') # 12  GRGR.. BGBG..
  SRGGB12 = v4l2_fourcc('R', 'G', '1', '2') # 12  RGRG.. GBGB..
  # 12bit raw bayer packed, 6 bytes for every 4 pixels
  SBGGR12P = v4l2_fourcc('p', 'B', 'C', 'C')
  SGBRG12P = v4l2_fourcc('p', 'G', 'C', 'C')
  SGRBG12P = v4l2_fourcc('p', 'g', 'C', 'C')
  SRGGB12P = v4l2_fourcc('p', 'R', 'C', 'C')
  # 14bit raw bayer packed, 7 bytes for every 4 pixels
  SBGGR14P = v4l2_fourcc('p', 'B', 'E', 'E')
  SGBRG14P = v4l2_fourcc('p', 'G', 'E', 'E')
  SGRBG14P = v4l2_fourcc('p', 'g', 'E', 'E')
  SRGGB14P = v4l2_fourcc('p', 'R', 'E', 'E')
  SBGGR16  = v4l2_fourcc('B', 'Y', 'R', '2') # 16  BGBG.. GRGR..
  SGBRG16  = v4l2_fourcc('G', 'B', '1', '6') # 16  GBGB.. RGRG..
  SGRBG16  = v4l2_fourcc('G', 'R', '1', '6') # 16  GRGR.. BGBG..
  SRGGB16  = v4l2_fourcc('R', 'G', '1', '6') # 16  RGRG.. GBGB..

  #
  # HSV formats
  #
  HSV24 = v4l2_fourcc('H', 'S', 'V', '3')
  HSV32 = v4l2_fourcc('H', 'S', 'V', '4')

  # compressed formats
  MJPEG          = v4l2_fourcc('M', 'J', 'P', 'G') # Motion-JPEG
  JPEG           = v4l2_fourcc('J', 'P', 'E', 'G') # JFIF JPEG
  DV             = v4l2_fourcc('d', 'v', 's', 'd') # 1394
  MPEG           = v4l2_fourcc('M', 'P', 'E', 'G') # MPEG-1/2/4 Multiplexed
  H264           = v4l2_fourcc('H', '2', '6', '4') # H264 with start codes
  H264_NO_SC     = v4l2_fourcc('A', 'V', 'C', '1') # H264 without start codes
  H264_MVC       = v4l2_fourcc('M', '2', '6', '4') # H264 MVC
  H263           = v4l2_fourcc('H', '2', '6', '3') # H263
  MPEG1          = v4l2_fourcc('M', 'P', 'G', '1') # MPEG-1 ES
  MPEG2          = v4l2_fourcc('M', 'P', 'G', '2') # MPEG-2 ES
  MPEG2_SLICE    = v4l2_fourcc('M', 'G', '2', 'S') # MPEG-2 parsed slice data
  MPEG4          = v4l2_fourcc('M', 'P', 'G', '4') # MPEG-4 part 2 ES
  XVID           = v4l2_fourcc('X', 'V', 'I', 'D') # Xvid
  VC1_ANNEX_G    = v4l2_fourcc('V', 'C', '1', 'G') # SMPTE 421M Annex G compliant stream
  VC1_ANNEX_L    = v4l2_fourcc('V', 'C', '1', 'L') # SMPTE 421M Annex L compliant stream
  VP8            = v4l2_fourcc('V', 'P', '8', '0') # VP8
  VP9            = v4l2_fourcc('V', 'P', '9', '0') # VP9
  HEVC           = v4l2_fourcc('H', 'E', 'V', 'C') # HEVC aka H.265
  FWHT           = v4l2_fourcc('F', 'W', 'H', 'T') # Fast Walsh Hadamard Transform (vicodec)
  FWHT_STATELESS = v4l2_fourcc('S', 'F', 'W', 'H') # Stateless FWHT (vicodec)

  #
  # Vendor-specific formats
  #
  CPIA1            = v4l2_fourcc('C', 'P', 'I', 'A') # cpia1 YUV
  WNVA             = v4l2_fourcc('W', 'N', 'V', 'A') # Winnov hw compress
  SN9C10X          = v4l2_fourcc('S', '9', '1', '0') # SN9C10x compression
  SN9C20X_I420     = v4l2_fourcc('S', '9', '2', '0') # SN9C20x YUV 4:2:0
  PWC1             = v4l2_fourcc('P', 'W', 'C', '1') # pwc older webcam
  PWC2             = v4l2_fourcc('P', 'W', 'C', '2') # pwc newer webcam
  ET61X251         = v4l2_fourcc('E', '6', '2', '5') # ET61X251 compression
  SPCA501          = v4l2_fourcc('S', '5', '0', '1') # YUYV per line
  SPCA505          = v4l2_fourcc('S', '5', '0', '5') # YYUV per line
  SPCA508          = v4l2_fourcc('S', '5', '0', '8') # YUVY per line
  SPCA561          = v4l2_fourcc('S', '5', '6', '1') # compressed GBRG bayer
  PAC207           = v4l2_fourcc('P', '2', '0', '7') # compressed BGGR bayer
  MR97310A         = v4l2_fourcc('M', '3', '1', '0') # compressed BGGR bayer
  JL2005BCD        = v4l2_fourcc('J', 'L', '2', '0') # compressed RGGB bayer
  SN9C2028         = v4l2_fourcc('S', 'O', 'N', 'X') # compressed GBRG bayer
  SQ905C           = v4l2_fourcc('9', '0', '5', 'C') # compressed RGGB bayer
  PJPG             = v4l2_fourcc('P', 'J', 'P', 'G') # Pixart 73xx JPEG
  OV511            = v4l2_fourcc('O', '5', '1', '1') # ov511 JPEG
  OV518            = v4l2_fourcc('O', '5', '1', '8') # ov518 JPEG
  STV0680          = v4l2_fourcc('S', '6', '8', '0') # stv0680 bayer
  TM6000           = v4l2_fourcc('T', 'M', '6', '0') # tm5600/tm60x0
  CIT_YYVYUY       = v4l2_fourcc('C', 'I', 'T', 'V') # one line of Y then 1 line of VYUY
  KONICA420        = v4l2_fourcc('K', 'O', 'N', 'I') # YUV420 planar in blocks of 256 pixels
  JPGL	           = v4l2_fourcc('J', 'P', 'G', 'L') # JPEG-Lite
  SE401            = v4l2_fourcc('S', '4', '0', '1') # se401 janggu compressed rgb
  S5C_UYVY_JPG     = v4l2_fourcc('S', '5', 'C', 'I') # S5C73M3 interleaved UYVY/JPEG
  Y8I              = v4l2_fourcc('Y', '8', 'I', ' ') # Greyscale 8-bit L/R interleaved
  Y12I             = v4l2_fourcc('Y', '1', '2', 'I') # Greyscale 12-bit L/R interleaved
  Z16              = v4l2_fourcc('Z', '1', '6', ' ') # Depth data 16-bit
  MT21C            = v4l2_fourcc('M', 'T', '2', '1') # Mediatek compressed block mode
  INZI             = v4l2_fourcc('I', 'N', 'Z', 'I') # Intel Planar Greyscale 10-bit and Depth 16-bit
  SUNXI_TILED_NV12 = v4l2_fourcc('S', 'T', '1', '2') # Sunxi Tiled NV12 Format
  CNF4             = v4l2_fourcc('C', 'N', 'F', '4') # Intel 4-bit packed depth confidence information

  # 10bit raw bayer packed, 32 bytes for every 25 pixels, last LSB 6 bits unused
  IPU3_SBGGR10 = v4l2_fourcc('i', 'p', '3', 'b') # IPU3 packed 10-bit BGGR bayer
  IPU3_SGBRG10 = v4l2_fourcc('i', 'p', '3', 'g') # IPU3 packed 10-bit GBRG bayer
  IPU3_SGRBG10 = v4l2_fourcc('i', 'p', '3', 'G') # IPU3 packed 10-bit GRBG bayer
  IPU3_SRGGB10 = v4l2_fourcc('i', 'p', '3', 'r') # IPU3 packed 10-bit RGGB bayer
end

#
# SDR formats - used only for Software Defined Radio devices
#
enum Linux::V4L2SDRFmt : Linux::U32
  CU8     = v4l2_fourcc('C', 'U', '0', '8') # IQ u8 *
  CU16LE  = v4l2_fourcc('C', 'U', '1', '6') # IQ u16le
  CS8     = v4l2_fourcc('C', 'S', '0', '8') # complex s8
  CS14LE  = v4l2_fourcc('C', 'S', '1', '4') # complex s14le
  RU12LE  = v4l2_fourcc('R', 'U', '1', '2') # real u12le
  PCU16BE = v4l2_fourcc('P', 'C', '1', '6') # planar complex u16be
  PCU18BE = v4l2_fourcc('P', 'C', '1', '8') # planar complex u18be
  PCU20BE	= v4l2_fourcc('P', 'C', '2', '0') # planar complex u20be
end

#
# Touch formats - used for Touch devices
#
enum Linux::V4L2TCHFmt : Linux::U32
  DELTA_TD16 = v4l2_fourcc('T', 'D', '1', '6') # 16-bit signed deltas
  DELTA_TD08 = v4l2_fourcc('T', 'D', '0', '8') # 8-bit signed deltas
  TU16       = v4l2_fourcc('T', 'U', '1', '6') # 16-bit unsigned touch data
  TU08       = v4l2_fourcc('T', 'U', '0', '8') # 8-bit unsigned touch data
end

#
# Meta-data formats
#
enum Linux::V4L2MetaFmt : Linux::U32
  VSP1_HGO = v4l2_fourcc('V', 'S', 'P', 'H') # R-Car VSP1 1-D Histogram
  VSP1_HGT = v4l2_fourcc('V', 'S', 'P', 'T') # R-Car VSP1 2-D Histogram
  UVC      = v4l2_fourcc('U', 'V', 'C', 'H') # UVC Payload Header metadata
  D4XX     = v4l2_fourcc('D', '4', 'X', 'X') # D4XX Payload Header metadata
end

lib Linux

  # priv field value to indicates that subsequent fields are valid.
  V4L2_PIX_FMT_PRIV_MAGIC = 0xfeedcafe

  # Flags
  V4L2_PIX_FMT_FLAG_PREMUL_ALPHA = 0x00000001

  @[Flags]
  enum V4L2FmtFlags : U32
    COMPRESSED             = 0x0001
    EMULATED               = 0x0002
    CONTINUOUS_BYTE_STREAM = 0x0004
    DYN_RESOLUTION         = 0x0008
  end

  struct V4L2FmtDesc
    index : U32 # Format number
    type : V4L2BufType
    flags : V4L2FmtFlags
    description : U8[32] # Description string
    pixelformat : V4L2PixFmt # Format fourcc
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

  union V4L2FrmSizeUnion
    discrete : V4L2FrmSizeDiscrete
    stepwise : V4L2FrmSizeStepWise
  end

  struct V4L2FrmSizeEnum
    index : U32        # Frame size number
    pixel_format : U32 # Pixel format
    type : V4L2FrmSizeTypes # Frame size type the device supports.

    frame_size : V4L2FrmSizeUnion # Frame size

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
    type : V4L2BufType
    memory : V4L2Memory
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
    type : V4L2BufType
    bytesused : U32
    flags : U32
    field : U32
    timestamp : LibC::Timeval
    timecode : V4L2TimeCode
    sequence : U32

    #
    # memory location
    #
    memory : V4L2Memory
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
    type : V4L2BufType
    index : U32
    plane : U32
    flags : V4L2BufFlags
    fd : S32
    reserved : U32[11]
  end

  struct V4L2FrameBufferFmt
    width, height : U32
    pixelformat : V4L2PixFmt
    field : V4L2Field
    bytesperline : U32 # for padding, zero if unused
    sizeimage : U32
    colorspace : V4L2ColorSpace
    priv : U32         # reserved field, set to 0
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
    field : V4L2Field
    chromakey : U32
    clips : V4L2Clip *
    clipcount : U32
    bitmap : Void *
    global_alpha : U8
  end

  struct V4L2CaptureParm
    capability : V4L2StreamingParmCap # Supported modes
    capturemode : V4L2CaptureParmFlags # Current mode
    timeperframe : V4L2Fract # Time per frame in seconds
    extendedmode : U32    # Driver-specific extensions
    readbuffers : U32     # # of buffers for read
    reserved : U32[4]
  end

  @[Flags]
  enum V4L2StreamingParmCap : U32
    TIMEPERFRAME = 0x1000
  end

  @[Flags]
  enum V4L2CaptureParmFlags : U32
    HIGHQUALITY = 0x0001
  end

  struct V4L2OutputParm
    capability : V4L2StreamingParmCap # Supported modes
    capturemode : V4L2CaptureParmFlags # Current mode
    timeperframe : V4L2Fract # Time per frame in seconds
    extendedmode : U32    # Driver-specific extensions
    readbuffers : U32     # # of buffers for read
    reserved : U32[4]
  end

  struct V4L2CropCap
    type : V4L2BufType
    bounds : V4L2Rect
    defrect : V4L2Rect
    pixelaspect : V4L2Fract
  end

  struct V4L2Crop
    tyep : V4L2BufType
    c : V4L2Rect
  end

  struct V4L2Selection
    type : V4L2BufType
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
    # Standards for Countries with 50Hz Line frequency
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
    type : V4L2DVTimingType
    union : V4L2DVTimingsUnion
  end

  enum V4L2DVTimingType : U32
    BT_656_1120 = 0 # BT.656/1120 timing type
  end

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
    type : V4L2DVTimingType
    pad : U32
    reserved : U32[2]
    union : V4L2DVTimingsCapUnion
  end

  struct V4L2Input
    index : U32
    name : U8[32]
    type : V4L2InputType
    audioset : U32
    tuner : U32
    std : V4L2StdID
    status : V4L2InputStatus
    capabilities : V4L2InputCap
    reserved : U32[3]
  end

  #
  # Values for the 'type' field
  #
  enum V4L2InputType : U32
    TUNER  = 1
    CAMERA = 2
    TOUCH  = 3
  end

  #
  # V4L2Input `status` field
  #
  @[Flags]
  enum V4L2InputStatus : U32
    #
    # field 'status' - general
    #
    NO_POWER  = 0x00000001  # Attached device is off
    NO_SIGNAL = 0x00000002
    NO_COLOR  = 0x00000004

    # field 'status' - sensor orientation
    # If sensor is mounted upside down set both bits
    HFLIP = 0x00000010 # Frames are flipped horizontally
    VFLIP = 0x00000020 # Frames are flipped vertically

    # field 'status' - analog
    NO_H_LOCK   = 0x00000100  # No horizontal sync lock
    COLOR_KILL  = 0x00000200  # Color killer is active
    NO_V_LOCK   = 0x00000400  # No vertical sync lock
    NO_STD_LOCK = 0x00000800  # No standard format lock

    # field 'status' - digital
    NO_SYNC     = 0x00010000  # No synchronization lock
    NO_EQU      = 0x00020000  # No equalizer lock
    NO_CARRIER  = 0x00040000  # Carrier recovery failed

    # field 'status' - VCR and set-top box
    MACROVISION = 0x01000000  # Macrovision detected
    NO_ACCESS   = 0x02000000  # Conditional access denied
    VTR         = 0x04000000  # VTR time constant
  end

  #
  # V4L2Input capabilities flags
  #
  @[Flags]
  enum V4L2InputCap : U32
    DV_TIMINGS     = 0x00000002 # Supports S_DV_TIMINGS
    CUSTOM_TIMINGS = DV_TIMINGS # For compatibility
    STD            = 0x00000004 # Supports S_STD
    NATIVE_SIZE    = 0x00000008 # Supports setting native size
  end

  struct V4L2Output
    index : U32           # Which output
    name : U8[32]         # Label
    type : V4L2OutputType # Type of output
    audioset : U32        #  Associated audios (bitfield)
    modulator : U32       # Associated modulator
    std : V4L2StdID
    capabilities : V4L2OutCap
    rserved : U32[3]
  end

  #  Values for the 'type' field
  enum V4L2OutputType : U32
    MODULATOR        = 1
    ANALOG           = 2
    ANALOGVGAOVERLAY = 3
  end

  # capabilities flags
  @[Flags]
  enum V4L2OutCap : U32
    DV_TIMINGS     = 0x00000002 # Supports S_DV_TIMINGS
    CUSTOM_TIMINGS = DV_TIMINGS # For compatibility
    STD            = 0x00000004 # Supports S_STD
    NATIVE_SIZE    = 0x00000008 # Supports setting native size
  end

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
    flags : V4L2CtrlFlags
    reserved : U32[2]
  end

  # Used in the VIDIOC_QUERY_EXT_CTRL ioctl for querying extended controls
  struct V4L2QueryExtCtrl
    id : U32
    type : V4L2CtrlType
    name : Char[32]
    minimum : S64
    maximum : S64
    step : U64
    default_value : S64
    flags : V4L2CtrlFlags
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

  @[Flags]
  enum V4L2CtrlFlags : U32
    DISABLED         = 0x0001
    GRABBED          = 0x0002
    READ_ONLY        = 0x0004
    UPDATE           = 0x0008
    INACTIVE         = 0x0010
    SLIDER           = 0x0020
    WRITE_ONLY       = 0x0040
    VOLATILE         = 0x0080
    HAS_PAYLOAD      = 0x0100
    EXECUTE_ON_WRITE = 0x0200
    MODIFY_LAYOUT    = 0x0400

    # Query flags, to be ORed with the control ID
    NEXT_CTRL     = 0x80000000
    NEXT_COMPOUND = 0x40000000
  end

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

  enum V4L2BandModulation : U32
    VSB = (1 << 1)
    FM  = (1 << 2)
    AM  = (1 << 3)
  end

  struct V4L2FrequencyBand
    tuner : U32
    type : V4L2TunerType
    index : U32
    capability : V4L2TunerCap
    rangelow : U32
    rangehigh : U32
    mdulation : V4L2BandModulation
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
    capability : V4L2AudioCap
    mode : V4L2AudioMode
    reserved : U32[2]
  end

  # Flags for the 'capability' field
  @[Flags]
  enum V4L2AudioCap
    STEREO = 0x00001
    AVL	   = 0x00002
  end

  # Flags for the 'mode' field
  @[Flags]
  enum V4L2AudioMode
    AVL = 0x00001
  end

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
    type : V4L2BufType
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
  # Event Types
  #
  enum V4L2EventType : U32
    ALL            = 0
    VSYNC          = 1
    EOS            = 2
    CTRL           = 3
    FRAME_SYNC     = 4
    SOURCE_CHANGE  = 5
    MOTION_DET     = 6
    PRIVATE_START  = 0x08000000
  end

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
    type : V4L2CtrlType
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
    type : V4L2EventType
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
    type : V4L2EventType
    id : U32
    flags : U32
    reserved : U32[5]
  end

  #
  # ADVANCED DEBUGGING
  #

  enum V4L2ChipMatch : U32
    # VIDIOC_DBG_G_REGISTER and VIDIOC_DBG_S_REGISTER
    BRIDGE      = 0  # Match against chip ID on the bridge (0 for the bridge)
    SUBDEV      = 4  # Match against subdev index

    # The following four defines are no longer in use
    HOST        = BRIDGE
    I2C_DRIVER  = 1  # Match against I2C driver name
    I2C_ADDR    = 2  # Match against I2C 7-bit address
    AC97        = 3  # Match against ancillary AC97 chip
  end

  @[Packed]
  union V4L2DbgMatchUnion
    addr : U32
    name : Char[32]
  end

  @[Packed]
  struct V4L2DbgMatch
    type : V4L2ChipMatch      # Match type
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
