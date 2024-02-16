SHELL       := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS   += --warn-undefined-variables
MAKEFLAGS   += --no-builtin-rules
STATE		?= sachsen
EXE			:= mtb$(STATE).exe
EXE			:= velo$(STATE).exe
MAPNAME		:= gmapsupp.img
URL			:= https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/germany/$(EXE)
URL			:= https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/velomap/germany/$(EXE)
CONVERT_SH	:= https://raw.githubusercontent.com/btittelbach/openmtbmap_openvelomap_linux/master/create_omtb_garmin_img.sh
OUT			:= out
STYLE		:= esyvdsh
# TODO calc today - 1; YY0101 is available for ever; but no md5?? file
DATE		:= 240101
GEOF		:= $(STATE)-240101.osm.pbf
GEOURL		:= https://download.geofabrik.de/europe/germany/
OUT			:= out
RAM			:= 1024M
SPLITTER	:= /usr/share/java/splitter/splitter.jar
MKGMAP		:= /usr/share/java/mkgmap/mkgmap.jar
MAXNODES	:= 900000

$(OUT):
	mkdir -p $@

$(EXE):
	@curl -L $(URL) -o $@

$(GEOF):
	curl -LO $(GEOURL)/$@

$(OUT)/template.args: | $(OUT)
	java \
		-Xmx$(RAM) \
		-jar "$(SPLITTER)" \
		--output-dir="$(OUT)" \
		--max-nodes=$(MAXNODES) \
		"$(GEOF)"

$(OUT)/osmmap.img: $(OUT)/template.args
	java \
		-Xmx$(RAM) \
		-jar "$(MKGMAP)" \
		--output-dir="$(OUT)" \
		--description="NETZEGO" \
		--family-id=42 \
		--style-file=styles \
		--style=test \
		--improve-overview \
		--read-config="$(OUT)/template.args" \
		"$(OUT)"/6*.pbf


$(OUT)/gmapsupp.img: $(OUT)/osmmap.img
	java \
		-Xmx$(RAM) \
		-jar "$(MKGMAP)" \
		--output-dir="$(OUT)" \
		--description="NETZEGO" \
		--family-id=42 \
		--style-file=styles \
		--style=test \
		--improve-overview \
		"$(OUT)"/6*.img
	
# no md5 file for yearly file
# $(GEOF).md5:
# 	curl -LO $(GEOURL)/$@
# 	md5sum -c $@

convert.zsh:
	curl -L $(CONVERT_SH) -o $@

sea.zip:
	curl -L -o $@ https://www.thkukuk.de/osm/data/sea-latest.zip

bounds.zip:
	curl -L -o $@ https://www.thkukuk.de/osm/data/bounds-latest.zip

$(MAPNAME): $(EXE) convert.zsh
	zsh convert.zsh $(EXE) $(STYLE)
	mv open*.img $(STATE)-gmapsupp.img
	ln $(STATE)-gmapsupp.img gmapsupp.img

clean:
	@# clean up; split up into clean and distclean
	@rm -fr $(EXE)
	@rm -fr $(CONVERT_SH)
	@rm -fr $(OUT)
	@rm -fr convert.zsh
	@rm -fr OMTB_tmp
	@rm -fr *.exe
	@rm -fr *.img
	@rm -fr *.tdb
	@rm -fr *.zip
	@rm -fr template.args
	@rm -fr 6*.pbf
	@rm -fr areas.*
	@rm -fr densities-out.txt

extract: $(EXE) |$(OUT)
	7z e -y -o$(OUT) $(EXE)

.PHONY: \
	clean

.DEFAULT_GOAL := $(MAPNAME)
