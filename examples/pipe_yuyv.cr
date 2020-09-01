require "../src/v4l2"
require "io/hexdump"

input_dev  = ARGV.fetch(0,"/dev/video0")
output_dev = ARGV.fetch(1,"/dev/video1")

begin
  V4L2::Device.open(input_dev) do |input|
    V4L2::Device.open(output_dev) do |output|
      input.video_capture.format do |format|
        format.width = 640
        format.height = 480
        format.pixel_format = V4L2::PixFmt::YUYV
      end

      format = input.video_capture.format
      puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

      output.video_output.format do |format|
        format.width = 640
        format.height = 480
        format.pixel_format = V4L2::PixFmt::YUYV
      end

      input.video_capture.malloc_buffers!(4, format.size_image)
      input.video_capture.capture! do
        system "ffplay #{output_dev} &"

        loop do
          input.video_capture.read_frame do |frame|
            output.write(frame.bytes)
          end
        end
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
