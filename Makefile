SHELL       := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS   += --warn-undefined-variables
MAKEFLAGS   += --no-builtin-rules
STATE		?= sachsen
EXE			:= velo$(STATE).exe
MAPNAME		:= gmapsupp.img
URL			:= https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/velomap/germany/$(EXE)
CONVERT_SH	:= https://raw.githubusercontent.com/btittelbach/openmtbmap_openvelomap_linux/master/create_omtb_garmin_img.sh
OUT			:= out
STYLE		:= esyvdsh

$(EXE):
	@curl -L $(URL) -o $@

convert.zsh:
	curl -L $(CONVERT_SH) -o $@

$(MAPNAME): $(EXE) convert.zsh
	zsh convert.zsh $(EXE) $(STYLE)
	mv open*.img $(STATE)-gmapsupp.img
	ln $(STATE)-gmapsupp.img gmapsupp.img

clean:
	@rm -fr $(EXE)
	@rm -fr $(CONVERT_SH)
	@rm -fr $(OUT)
	@rm -fr convert.zsh
	@rm -fr OMTB_tmp
	@rm -fr *.exe
	@rm -fr *.img
	@rm -fr *.tdb

$(OUT):
	mkdir -p $@

extract: $(EXE) |$(OUT)
	7z e -y -o$(OUT) $(EXE)

.PHONY: \
	clean

.DEFAULT_GOAL := $(MAPNAME)
