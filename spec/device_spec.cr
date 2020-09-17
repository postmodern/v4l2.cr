require "./spec_helper"

Spectator.describe V4L2::Device do
  subject { described_class.open(VIDEO_DEV) }

  describe ".open" do
    it "should open a new file descriptor" do
      expect(subject.fd).to be > STDERR.fd
    end
  end

  describe "#capabilities" do
    it "should automatically be populated" do
      expect(subject.capability).to be_kind_of(V4L2::Capability)
    end
  end

  describe "#video_capture" do
    context "when the video device supports VIDEO_CAPTURE" do
      it "should initialize #video_capture" do
        if subject.capability.video_capture?
          expect(subject.video_capture).to be_kind_of(V4L2::Streams::VideoCapture)
        end
      end
    end

    context "when the video device does not support VIDEO_CAPTURE" do
      it "must raise an V4L2::Device::UnsupportedCapability exception" do
        #pending "figure out how to test this edge-case"
      end
    end
  end

  describe "#video_output" do
    context "when the video device supports VIDEO_OUTPUT" do
      it "should initialize #video_output" do
        if subject.capability.video_output?
          expect(subject.video_output).to be_kind_of(V4L2::Streams::VideoOutput)
        end
      end
    end

    context "when the video device does not support VIDEO_OUTPUT" do
      it "must raise an V4L2::Device::UnsupportedCapability exception" do
        #pending "figure out how to test this edge-case"
      end
    end
  end

  {% for name in [:video_overlay, :vbi_capture, :vbi_output, :sliced_vbi_capture, :sliced_vbi_output, :video_output_overlay, :video_capture_mplane, :video_output_mplane, :sdr_capture, :sdr_output, :meta_capture, :meta_output] %}
    describe "#{{ name.id }}" do
      context "when the video device supports {{ name.id.upcase }}" do
        it "should initialize \# {{ name.id }}" do
          #pending "figure out how to test this edge-case"
        end
      end

      context "when the video device does not support {{ name.id.upcase }}" do
        it do
          expect { subject.{{ name.id }}}.to raise_error(V4L2::Device::UnsupportedCapability)
        end
      end
    end
  {% end %}

  after_each { subject.close }
end
