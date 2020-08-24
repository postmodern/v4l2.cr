require "./videodev2"
require "./media-buf-format"

lib Linux
  struct V4L2MBusFrameFmt
    width : U32
    height : U32
    code : U32
    field : U32
    colorspace : U32
    ycbcr_enc : U16
    quantization : U16
    xfer_func : U16
    reserved : U16[11]
  end

  {% begin %}
  enum V4L2MBusPixelCode
    {% for name in [
        :FIXED,

        :RGB444_2X8_PADHI_BE,
        :RGB444_2X8_PADHI_LE,
        :RGB555_2X8_PADHI_BE,
        :RGB555_2X8_PADHI_LE,
        :BGR565_2X8_BE,
        :BGR565_2X8_LE,
        :RGB565_2X8_BE,
        :RGB565_2X8_LE,
        :RGB666_1X18,
        :RGB888_1X24,
        :RGB888_2X12_BE,
        :RGB888_2X12_LE,
        :ARGB8888_1X32,

        :Y8_1X8,
        :UV8_1X8,
        :UYVY8_1_5X8,
        :VYUY8_1_5X8,
        :YUYV8_1_5X8,
        :YVYU8_1_5X8,
        :UYVY8_2X8,
        :VYUY8_2X8,
        :YUYV8_2X8,
        :YVYU8_2X8,
        :Y10_1X10,
        :UYVY10_2X10,
        :VYUY10_2X10,
        :YUYV10_2X10,
        :YVYU10_2X10,
        :Y12_1X12,
        :UYVY8_1X16,
        :VYUY8_1X16,
        :YUYV8_1X16,
        :YVYU8_1X16,
        :YDYUYDYV8_1X16,
        :UYVY10_1X20,
        :VYUY10_1X20,
        :YUYV10_1X20,
        :YVYU10_1X20,
        :YUV10_1X30,
        :AYUV8_1X32,
        :UYVY12_2X12,
        :VYUY12_2X12,
        :YUYV12_2X12,
        :YVYU12_2X12,
        :UYVY12_1X24,
        :VYUY12_1X24,
        :YUYV12_1X24,
        :YVYU12_1X24,

        :SBGGR8_1X8,
        :SGBRG8_1X8,
        :SGRBG8_1X8,
        :SRGGB8_1X8,
        :SBGGR10_ALAW8_1X8,
        :SGBRG10_ALAW8_1X8,
        :SGRBG10_ALAW8_1X8,
        :SRGGB10_ALAW8_1X8,
        :SBGGR10_DPCM8_1X8,
        :SGBRG10_DPCM8_1X8,
        :SGRBG10_DPCM8_1X8,
        :SRGGB10_DPCM8_1X8,
        :SBGGR10_2X8_PADHI_BE,
        :SBGGR10_2X8_PADHI_LE,
        :SBGGR10_2X8_PADLO_BE,
        :SBGGR10_2X8_PADLO_LE,
        :SBGGR10_1X10,
        :SGBRG10_1X10,
        :SGRBG10_1X10,
        :SRGGB10_1X10,
        :SBGGR12_1X12,
        :SGBRG12_1X12,
        :SGRBG12_1X12,
        :SRGGB12_1X12,

        :JPEG_1X8,

        :S5C_UYVY_JPEG_1X8,

        :AHSV8888_1X32,
                   ] %}
      {{ name.id }} = MEDIA_BUS_FMT_{{ name.id }}
    end
    {% end %}
  end
  {% end %}
end
