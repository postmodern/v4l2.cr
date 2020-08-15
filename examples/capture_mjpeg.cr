require "../src/v4l2"

video = ARGV.fetch(0,"/dev/video0")

begin
  V4L2::Device.open(video) do |device|
    device.video_capture.format do |format|
      format.width = 640
      format.height = 480
      format.pixel_format = V4L2::PixFmt::MJPEG
    end

    format = device.video_capture.format
    puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

    device.video_capture.malloc_buffers!(4, format.size_image)
    device.video_capture.capture! do
      30.times do |i|
        device.video_capture.read_frame do |frame|
          File.write("image-#{i}.jpg",frame.bytes)
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
