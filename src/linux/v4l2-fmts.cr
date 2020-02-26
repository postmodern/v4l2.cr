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
