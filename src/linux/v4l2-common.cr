require "./types"

lib Linux
  #
  # Selection interface definitions
  #
  
  # Current cropping area
  V4L2_SEL_TGT_CROP		= 0x0000
  # Default cropping area
  V4L2_SEL_TGT_CROP_DEFAULT	= 0x0001
  # Cropping bounds
  V4L2_SEL_TGT_CROP_BOUNDS	= 0x0002
  # Native frame size
  V4L2_SEL_TGT_NATIVE_SIZE	= 0x0003
  # Current composing area
  V4L2_SEL_TGT_COMPOSE		= 0x0100
  # Default composing area
  V4L2_SEL_TGT_COMPOSE_DEFAULT	= 0x0101
  # Composing bounds
  V4L2_SEL_TGT_COMPOSE_BOUNDS	= 0x0102
  # Current composing area plus all padding pixels
  V4L2_SEL_TGT_COMPOSE_PADDED	= 0x0103
  
  # Selection flags
  V4L2_SEL_FLAG_GE		= (1 << 0)
  V4L2_SEL_FLAG_LE		= (1 << 1)
  V4L2_SEL_FLAG_KEEP_CONFIG	= (1 << 2)

  struct V4L2EDID
    pad : U32
    start_block : U32
    blocks : U32
    reserved : U32[5]
    edid : U8 *
  end

  # Backward compatibility target definitions --- to be removed.
  V4L2_SEL_TGT_CROP_ACTIVE           = V4L2_SEL_TGT_CROP
  V4L2_SEL_TGT_COMPOSE_ACTIVE	       = V4L2_SEL_TGT_COMPOSE
  V4L2_SUBDEV_SEL_TGT_CROP_ACTUAL	   = V4L2_SEL_TGT_CROP
  V4L2_SUBDEV_SEL_TGT_COMPOSE_ACTUAL = V4L2_SEL_TGT_COMPOSE
  V4L2_SUBDEV_SEL_TGT_CROP_BOUNDS	   = V4L2_SEL_TGT_CROP_BOUNDS
  V4L2_SUBDEV_SEL_TGT_COMPOSE_BOUNDS = V4L2_SEL_TGT_COMPOSE_BOUNDS

  # Backward compatibility flag definitions --- to be removed.
  V4L2_SUBDEV_SEL_FLAG_SIZE_GE     = V4L2_SEL_FLAG_GE
  V4L2_SUBDEV_SEL_FLAG_SIZE_LE     = V4L2_SEL_FLAG_LE
  V4L2_SUBDEV_SEL_FLAG_KEEP_CONFIG = V4L2_SEL_FLAG_KEEP_CONFIG
end
