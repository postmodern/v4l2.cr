# v4l2.cr

WIP [Crystal][crystal] bindings for [libv4l2][v4l2].

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

## Usage

```crystal
require "v4l2"
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
