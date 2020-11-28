VIDEO_DEV?=/dev/video0

test:
	sudo modprobe v4l2loopback
	VIDEO_DEV=$(VIDEO_DEV) crystal spec

.PHONY: test
