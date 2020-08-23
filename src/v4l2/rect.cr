require "../linux/videodev2"

module V4L2
  record Rect, left : Int32, top : Int32, width : UInt32, height : UInt32 do

    def initialize(rect_struct : Linux::V4L2Rect)
      initialize(
        rect_struct.left,
        rect_struct.top,
        rect_struct.width,
        rect_struct.height,
      )
    end

    def to_unsafe : Linux::V4L2Rect
      rect_struct = Linux::V4L2Rect.new
      rect_struct.left   = left
      rect_struct.top    = top
      rect_struct.width  = width
      rect_struct.height = height
      return rect_struct
    end

  end
end
