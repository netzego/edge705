#!/bin/bash

# TODO
# check parameter

declare -gr PBF="${1:-}"
declare -gr TYP="${2:-}"
declare -gr RAM=1000M
declare -gr MKGMAP=/usr/share/java/mkgmap/mkgmap.jar
declare -gr SPLITTER=/usr/share/java/splitter/splitter.jar
declare -gr WORKDIR="$(mktemp --tmpdir -d "$0-XXXXXXXX")"
declare -gr OUTDIR="$(mktemp -d "out-XXXXXXXX")"

trap cleanup EXIT

cleanup() {
	rm -frv "$WORKDIR"
}

split_map() {
	# https://www.mkgmap.org.uk/doc/splitter.html

	java \
		-Xmx"$RAM" \
		-jar "$SPLITTER" \
		--output-dir="$OUTDIR" \
		--max-nodes=900000 \
		"${PBF}"
}

gen_img_files() {
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
	# declare -r _typ="$WORKDIR/$TYP"
	# declare -r _typ="$(ls -1 $WORKDIR/race*.TYP)"

	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	java \
		-Xmx"$RAM" \
		-jar "$MKGMAP" \
		--output-dir="$OUTDIR" \
		--description="$_desc" \
		--family-id=42 \
		--style-file=styles \
		--style=test \
		--improve-overview \
		--remove-short-arcs \
		--route \
		--net \
		--read-config="${OUTDIR}/template.args" \
		"${OUTDIR}"/6*.pbf
}

gen_gmapsupp() {
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	java \
		-Xmx"$RAM" \
		-jar "$MKGMAP" \
		--output-dir="$OUTDIR" \
		--style-file=styles \
		--style=test \
		--gmapsupp \
		"${OUTDIR}"/6*.img
}

split_map
gen_img_files
# gen_gmapsupp

exit 0
