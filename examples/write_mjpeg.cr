require "../src/v4l2"

video = ARGV.fetch(0,"/dev/video0")

unless File.exists?(video)
  puts "Loading v4l2loopback kernel module ..."
  system "sudo modprobe v4l2loopback"
end

# sleep 1
# puts "Starting mpv ..."
# system "mpv /dev/video1"

begin
  V4L2::Device.open(video) do |device|
    device.video_output.format do |format|
      format.width = 640
      format.height = 480
      format.pixel_format = V4L2::PixFmt::MJPEG
    end

    format = device.video_output.format
    puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

    puts "Parm: #{device.video_output.parm.inspect}"

    images  = Dir["image-*.jpg"]
    buffers = Array(Bytes).new(images.size) do |index|
      Bytes.new(format.size_image).tap do |buffer|
        File.open(images[index],"rb") do |file|
          file.read(buffer)
        end
      end
    end

    puts "Spawning mpv ..."
    system "mpv #{video} &"

    puts "Streaming ..."
    loop do
      buffers.each do |buffer|
        device.write(buffer)
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
