build:
	echo "building"
	zig build

release:
	echo 'building for release'
	zig build --release=Fast


