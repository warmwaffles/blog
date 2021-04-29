all: build

build:
	hugo

publish: build
	rclone sync ./public amazon:mattjohnston.co
