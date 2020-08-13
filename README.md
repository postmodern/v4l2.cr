# v4l2.cr

WIP [Crystal][crystal] bindings for [libv4l2][v4l2].

## Requirements

* Linux
* Crystal >= 0.35.1

## Installation

1. Install the v4l2 libraries and headers:

  * Debian / Ubuntu

         $ sudo apt install libv4l-dev

   * RedHat / Fedora

         $ sudo dnf install libv4l-devel

2. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal-v4l2:
       github: postmodern/v4l2.cr
   ```

2. Run `shards install`

## Examples

Reading a single JPEG frame:

```crystal
require "v4l2"

V4L2::Device.open("/dev/video0") do |device|
  device.video_capture.format do |format|
    format.width = 640
    format.height = 480
    format.pixel_format = Linux::V4L2PixFmt::MJPEG
  end

  format = device.video_capture.format
  puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

  device.video_capture.malloc_buffers!(4_u32, format.size_image)
  device.video_capture.start_capturing!
  device.video_capture.stream_on!

  device.video_capture.read_frame do |frame|
    File.write("image.jpg",frame.bytes)
  end

  device.video_capture.stream_off!
end
```

## TODO

* Implement YUYV 422 pixel format support.

## Contributing

1. Fork it (<https://github.com/postmodern/crystal-v4l2/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Postmodern](https://github.com/postmodern) - creator and maintainer

[crystal]: https://crystal-lang.org/
[v4l2]: https://linuxtv.org/downloads/v4l-dvb-apis/uapi/v4l/v4l2.html
