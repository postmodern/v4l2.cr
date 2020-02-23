require "./linux/videodev2"

@[Link("v4lconvert")]
lib Lib4LConvert
  alias Int = LibC::Int
  alias LibV4LDevOps = LibV4L2::LibV4LDevOps

  alias V4LConvertDataPtr = Void *

  fun v4lconvert_get_default_dev_ops() : LibV4LDevOps *
  fun v4lconvert_create(fd : Int) : V4LConvertDataPtr
  fun v4lconvert_create_with_dev_ops(fd : Int, dev_ops_priv : Void*, dev_ops : LibV4LDevOps*) : V4LConvertDataPtr
  fun v4lconvert_destroy(data : V4LConvertDataPtr)
end
