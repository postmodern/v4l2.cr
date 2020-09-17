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
      xit "must raise an V4L2::Device::UnsupportedCapability exception" do
        expect { subject.video_capture }.to raise_error(V4L2::Device::UnsupportedCapability)
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
      xit "must raise an V4L2::Device::UnsupportedCapability exception" do
        expect { subject.video_output }.to raise_error(V4L2::Device::UnsupportedCapability)
      end
    end
  end

  {% for name, constant in {:video_overlay => :VideoOverlay, :vbi_capture => :VBICapture, :vbi_output => :VBIOutput, :sliced_vbi_capture => :SlicedVBICapture, :sliced_vbi_output => :SlicedVBIOutput, :video_output_overlay => :VideoOutputOverlay, :video_capture_mplane => :VideoCaptureMPlane, :video_output_mplane => :VideoOutputMPlane, :sdr_capture => :SDRCapture, :sdr_output => :SDROutput, :meta_capture => :MetaCapture, :meta_output => :MetaOutput} %}
    describe "#{{ name.id }}" do
      context "when the video device supports {{ name.id.upcase }}" do
        xit "should initialize \#{{ name.id }}" do
          expect(subject.{{ name.id }}).to be_kind_of(V4L2::Streams::{{ constant.id }})
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
