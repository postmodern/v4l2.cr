require "./v4l2-common"
require "./v4l2-mediabus"

lib Linux
  enum V4L2SubdevFormatWhence
    TRY = 0
    ACTIVE = 1
  end

  struct V4L2SubdevFormat
    which : U32
    pad : U32
    format : V4L2MBusFrameFmt
    reserved : U32[8]
  end

  struct V4L2SubdevCrop
    which : U32
    pad : U32
    rect : V4L2Rect
    reserved : U32[8]
  end

  struct V4L2SubdevMBusCodeEnum
    pad : U32
    index : U32
    code : U32
    which : U32
    reserved : U32[8]
  end

  struct V4L2SubdevFrameSizeEnum
    index : U32
    pad : U32
    code : U32
    min_width : U32
    max_width : U32
    min_height : U32
    max_height : U32
    which : U32
    reserved : U32[8]
  end

  struct V4L2SubdevFrameInterval
    pad : U32
    interval : V4L2Fract
    reserved : U32[9]
  end

  struct V4L2SubdevFrameIntervalEnum
    index : U32
    pad : U32
    code : U32
    width : U32
    heght : U32
    interval : V4L2Fract
    which : U32
    reserved : U32[8]
  end

  struct V4L2SubdevSelection
    which : U32
    pad : U32
    target : U32
    flags : U32
    r : V4L2Rect
    reserved : U32[8]
  end

  alias V4L2SubdevEDID = V4L2EDID

  VIDIOC_SUBDEV_G_FMT = ioctl_iowr('V',  4, V4L2SubdevFormat)
  VIDIOC_SUBDEV_S_FMT = ioctl_iowr('V',  5, V4L2Subdev_format)
  VIDIOC_SUBDEV_G_FRAME_INTERVAL = ioctl_iowr('V', 21, V4L2SubdevFrameInterval)
  VIDIOC_SUBDEV_S_FRAME_INTERVAL = ioctl_iowr('V', 22, V4L2SubdevFrameInterval)
  VIDIOC_SUBDEV_ENUM_MBUS_CODE = ioctl_iowr('V',  2, V4L2SubdevMBusCodeEnum)
  VIDIOC_SUBDEV_ENUM_FRAME_SIZE = ioctl_iowr('V', 74, V4L2SubdevFrameSizeEnum)
  VIDIOC_SUBDEV_ENUM_FRAME_INTERVAL = ioctl_iowr('V', 75, V4L2SubdevFrameIntervalEnum)
  VIDIOC_SUBDEV_G_CROP = ioctl_iowr('V', 59, V4L2SubdevCrop)
  VIDIOC_SUBDEV_S_CROP = ioctl_iowr('V', 60, V4L2SubdevCrop)
  VIDIOC_SUBDEV_G_SELECTION = ioctl_iowr('V', 61, V4L2SubdevSelection)
  VIDIOC_SUBDEV_S_SELECTION = ioctl_iowr('V', 62, V4L2SubdevSelection)
  # The following ioctls are identical to the ioctls in videodev2.h */
  VIDIOC_SUBDEV_G_STD = ioctl_ior('V', 23, V4L2StdID)
  VIDIOC_SUBDEV_S_STD = ioctl_iow('V', 24, V4L2StdID)
  VIDIOC_SUBDEV_ENUMSTD = ioctl_iowr('V', 25, V4L2Standard)
  VIDIOC_SUBDEV_G_EDID = ioctl_iowr('V', 40, V4L2EDID)
  VIDIOC_SUBDEV_S_EDID = ioctl_iowr('V', 41, V4L2EDID)
  VIDIOC_SUBDEV_QUERYSTD = ioctl_ior('V', 63, V4L2StdID)
  VIDIOC_SUBDEV_S_DV_TIMINGS = ioctl_iowr('V', 87, V4L2DVTimings)
  VIDIOC_SUBDEV_G_DV_TIMINGS = ioctl_iowr('V', 88, V4L2DVTimings)
  VIDIOC_SUBDEV_ENUM_DV_TIMINGS = ioctl_iowr('V', 98, V4L2EnumDVTimings)
  VIDIOC_SUBDEV_QUERY_DV_TIMINGS = ioctl_ior('V', 99, V4L2DVTimings)
  VIDIOC_SUBDEV_DV_TIMINGS_CAP = ioctl_iowr('V', 100, V4L2DVTimingsCap)
end
