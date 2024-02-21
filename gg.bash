#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

IFS=$' \n\t'

# declare -gr BUILDDIR="$(mktemp -d "out-XXXXXXXX")"

declare -gr SCRIPTDIR="$(dirname "$(realpath "${BASH_ARGV0}")")"
declare -gr RAM=2048M
declare -gr MKGMAP=/usr/share/java/mkgmap/mkgmap.jar
declare -gr MKGMAP_MAXNODES=1000000
declare -gr SPLITTER=/usr/share/java/splitter/splitter.jar
declare -gr PBF=map.osm.pbf
declare -gr GEOF_DATADIR=data
declare -gr GEOF_URL="https://download.geofabrik.de/europe/germany/"
# declare -gr GEOF_DATE="$(($(date +%y%m%d) - 1))"
declare -gr GEOF_SUBREGIONS=(
	berlin
	brandenburg
	bremen
	hamburg
	niedersachsen
	sachsen
	sachsen-anhalt
	thueringen
)

# ensures that $GEOF_DATADIR exists
datadir() {
	if [[ ! -d "${GEOF_DATADIR}" ]]; then
		mkdir -v "${GEOF_DATADIR}"
	fi
}

# download all latest geofabrik subregion
download() {
	for _region in "${GEOF_SUBREGIONS[@]}"; do
		declare _filename="${_region}-latest.osm.pbf"
		declare _url="${GEOF_URL}/${_filename}"

		if [[ ! -f $GEOF_DATADIR/$_filename || ! -f $GEOF_DATADIR/$_filename.md5 ]]; then
			curl -LO --output-dir "${GEOF_DATADIR}" "${_url}"
			curl -LO --output-dir "${GEOF_DATADIR}" "${_url}.md5"
		fi
	done
}

# verify all pbf files from geofabrik
verify() {
	pushd "${GEOF_DATADIR}"

	for _region in "${GEOF_SUBREGIONS[@]}"; do
		declare _md5file="${_region}-latest.osm.pbf.md5"

		if ! md5sum -c "${_md5file}"; then
			echo "error: 'md5sum -c ${_md5file}' inside '${GEOF_DATADIR}' failed"
			exit 1
		fi
	done

	popd
}

# merge all subregions to one pbf file
merge() {
	osmium merge \
		"${GEOF_DATADIR}/*-latest.osm.pbf" \
		--overwrite \
		--output "${GEOF_DATADIR}/${PBF}"
}

# generates tiles with less then x datapoints
split() {
	java \
		-Xmx"${RAM}" \
		-jar "${SPLITTER}" \
		--output-dir="${GEOF_DATADIR}" \
		--max-nodes=${MKGMAP_MAXNODES} \
		"${GEOF_DATADIR}/${PBF}"
}

# generates 6*.img files
generate_map() {
	java \
		-Xmx"${RAM}" \
		-jar "${MKGMAP}" \
		--output-dir="${GEOF_DATADIR}" \
		--route \
		--net \
		--improve-overview \
		--remove-short-arcs \
		--read-config="${GEOF_DATADIR}/template.args" \
		--gmapsupp \
		"${GEOF_DATADIR}"/6*.osm.pbf
}

datadir
download
verify
merge
split
generate_map

exit 0
