#!/bin/bash

# TODO
# check parameter

declare -gr EXE=$1
declare -gr TYP=$2
declare -gr RAM=1000M
declare -gr MKGMAP=/usr/share/java/mkgmap/mkgmap.jar
declare -gr WORKDIR="$(mktemp --tmpdir -d "$0-XXXXXXXX")"

# trap cleanup EXIT

cleanup() {
	rm -frv "$WORKDIR"
}

extract_exe() {
	7z e -y -o"$WORKDIR" "$EXE" &>/dev/null
}

generate_map() {
	# https://www.mkgmap.org.uk/doc/options
	# --description:
	# --series-name: displayed by garmin pc programs; default: `OSM map`
	# --family-name: defualt: `OSM map`
	# --show-profiles: sets flag for DEM (hill shading) data
	# --product-id: `it is often just 1, which is the default` LOL
	# --index: generate an address index
	# --family-id: integer 1..65535 (start w/ 1?)
	declare -r _desc="netzego"
	declare -r _fid="4242"

	java \
		-Xmx"$RAM" \
		-jar "$MKGMAP" \
		--description="$_desc" \
		--family-id=42 \
		--style=routes-bicycle \
		--gmapsupp ${WORKDIR}/{6,7}*.img
}

echo $WORKDIR

extract_exe "$EXE"
generate_map

exit 0
