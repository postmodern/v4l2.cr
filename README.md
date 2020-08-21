# v4l2.cr

[Crystal][crystal] bindings for [V4L2][v4l2] (Video for Linux 2 API).

## Requirements

* Linux
* [Crystal][crystal] >= 0.35.1

## Installation

1. Add the dependency to your `shard.yml`:

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
    format.pixel_format = V4L2::PixFmt::MJPEG
  end

  format = device.video_capture.format
  puts "Format: #{format.pixel_format} #{format.width}x#{format.height}"

  device.video_capture.malloc_buffers!(4, format.size_image)
  device.video_capture.capture! do
    device.video_capture.read_frame do |frame|
      File.write("image.jpg",frame.bytes)
    end
  end
end
```

See [examples] for additional examples.

## TODO

* Add `CropCap` and `Crop` classes.
* Document public API.
* Write specs meant to be ran manually with a webcam.

## Contributing

1. Fork it (<https://github.com/postmodern/crystal-v4l2/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Postmodern](https://github.com/postmodern) - creator and maintainer

[crystal]: https://crystal-lang.org/
[v4l2]: https://www.kernel.org/doc/html/v4.9/media/uapi/v4l/v4l2.html
[examples]: https://github.com/postmodern/v4l2.cr/tree/master/examples
