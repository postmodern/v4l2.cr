require "../src/v4l2"
require "io/hexdump"

video = ARGV.fetch(0,"/dev/video0")

begin
  V4L2::Device.open(video) do |device|
    device.video_capture.format do |format|
      format.width = 640
      format.height = 480
      format.pixel_format = V4L2::PixFmt::YUYV
    end

    format = device.video_capture.format
    puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

    dummy = Bytes.new(format.size_image)

    device.video_capture.malloc_buffers!(4, format.size_image)
    device.video_capture.capture! do
      device.video_capture.read_frame do |frame|
        mem = IO::Memory.new(frame.bytes, writeable: false)
        hexdump = IO::Hexdump.new(mem, output: STDOUT, read: true)
        hexdump.read(dummy)
      end
    end
  end
rescue error : V4L2::Error
  STDERR.puts error.message
  error.backtrace.each do |line|
    STDERR.puts "\t#{line}"
  end
  exit -1
end
