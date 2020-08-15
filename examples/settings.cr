require "../src/v4l2"

video = ARGV.fetch(0,"/dev/video0")

begin
  V4L2::Device.open(video) do |device|
    capability = device.capability

    puts
    puts "Driver:\t#{String.new(capability.driver.to_slice)}"
    puts "Card:\t#{String.new(capability.card.to_unsafe)}"
    puts "Capabilities:\t#{capability.capabilities}"
    puts "Device Caps:\t#{capability.device_caps}"

    # format = device.format
    # p format

    # frame_buffer = device.frame_buffer
    # p frame_buffer

    # device.overlay = true

    # p device.standard

    # device.each_standard do |standard|
    #   p standard
    # end

    puts "Formats:"
    device.video_capture.each_format do |format|
      puts "  [#{format.index}] #{format.description}"

      format.each_frame_size do |frame_size|
        puts "      #{frame_size}"
      end
    end

    device.video_capture.format do |format|
      format.width = 640
      format.height = 480
      format.pixel_format = V4L2::PixFmt::MJPEG
    end

    format = device.video_capture.format
    puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

    puts "Input: #{device.input}"
    puts "Inputs:"
    device.each_input do |input|
      puts "  [#{input.index}] #{input.inspect}"
    end

    puts "Parm: #{device.video_capture.parm.inspect}"

    # p device.edid
    # puts "Output: #{device.output}"
    # puts "Outputs:"
    # device.each_output do |output|
    #   puts "  [#{output.index}] #{output.inspect}"
    # end

    # puts "Audio: #{device.audio}"
    # puts "Audios:"
    # device.each_audio do |audio|
    #   puts "  [#{audio.index}] #{audio.inspect}"
    # end

    # puts "Audio Outs:"
    # device.each_audio_out do |audio_out|
    #   puts "  [#{audio_out.index}] #{audio_out.inspect}"
    # end

    # p device.sliced_vbi_capabilities(V4L2::Buffer::Type::VIDEO_CAPTURE)

    # puts "Modulator: #{device.modulator.inspect}"
    # puts "Frequency: #{device.frequency}"

    # puts "Crop Capabilities: #{device.crop_capabilities(V4L2::Buffer::Type::VIDEO_CAPTURE).inspect}"
    # p device.crop(V4L2::Buffer::Type::VIDEO_CAPTURE)

    # puts "Priority: #{device.priority}"

    # device.log_status
  end
rescue error : V4L2::Error
  STDERR.puts error.message
  error.backtrace[0..4].each do |line|
    STDERR.puts "\t#{line}"
  end
  exit -1
end
