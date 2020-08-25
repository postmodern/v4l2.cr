require "./spec_helper"

Spectator.describe V4L2 do
  {% for type in [:Field, :PixFmt, :ColorSpace, :XFERFunc, :YCbCrEncoding, :HSVEncoding, :Quantization, :Priority] %}
    describe "{{ type.id }}" do
      it { expect(V4L2::{{ type.id }}).to be(Linux::V4L2{{ type.id }}) }
    end
  {% end %}
end
