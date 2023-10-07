SHELL       := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS   += --warn-undefined-variables
MAKEFLAGS   += --no-builtin-rules
STATE		?= sachsen
EXE			:= velo$(STATE).exe
MAPNAME		:= gmapsupp.img
URL			:= https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/velomap/germany/$(EXE)
CONVERT_SH	:= https://raw.githubusercontent.com/btittelbach/openmtbmap_openvelomap_linux/master/create_omtb_garmin_img.sh

$(EXE):
	curl -L $(URL) -o $@

convert.zsh:
	curl -L $(CONVERT_SH) -o $@

$(MAPNAME): $(EXE) convert.zsh
	zsh convert.zsh $(EXE) velo
	mv openvelo*.img $(STATE).gmapsupp.img

clean:
	@rm -f *exe
	@rm -f *sh

.PHONY: \
	clean

.DEFAULT_GOAL := $(MAPNAME)
