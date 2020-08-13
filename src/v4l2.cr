require "./libv4l2"
require "./libv4l2rds"
require "./libv4lconvert"
require "./v4l2/device"

module V4L2
  VERSION = "0.1.0"

  alias Field = Linux::V4L2Field
  alias PixelFormat = Linux::V4L2PixFmt
  alias ColorSpace = Linux::V4L2ColorSpace
  alias XFERFunc = Linux::V4L2XFERFunc
  alias YCBCREncoding = Linux::V4L2YCBCREncoding
  alias HSVEncoding = Linux::V4L2HSVEncoding
  alias Quantization = Linux::V4L2Quantization
  alias Priority = Linux::V4L2Priority
end
