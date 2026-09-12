# Mega Drive / Genesis homebrew of Kiko: Wild Fury - Matajava
# Requires marsdev/SGDK: m68k-elf-gcc + rescomp.jar
#   export GDK=/opt/toolchains/mars/m68k-elf
#   make

GDK ?= /opt/toolchains/mars/m68k-elf
export GDK
export PATH := $(GDK)/bin:$(PATH)

PYTHON ?= python3
DIST := ../dist

.PHONY: all gfx rom dist clean

all: gfx rom dist

gfx:
	$(PYTHON) tools/pack_assets.py

rom: gfx
	mkdir -p src/boot out
	cp -f header/rom_head.c src/boot/rom_head.c
	touch src/boot/rom_head.c
	$(MAKE) -f $(GDK)/makefile.gen
	cp -f header/rom_head.c src/boot/rom_head.c
	$(PYTHON) tools/fix_checksum.py out/rom.bin

dist: rom
	mkdir -p $(DIST)
	cp -f out/rom.bin $(DIST)/KikoWildFuryMatajava.bin
	cp -f out/rom.bin $(DIST)/KikoWildFuryMatajava.md
	cp -f out/rom.bin $(DIST)/KikoWildFuryMatajava.gen

clean:
	$(MAKE) -f $(GDK)/makefile.gen clean
	rm -rf out src/boot
