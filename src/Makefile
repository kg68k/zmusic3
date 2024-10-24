# Makefile for Z-MUSIC Ver.3

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

SRCDIR_MK = ../srcdir.mk
SRC_DIR = ../src
-include $(SRCDIR_MK)

AS = has060
ASFLAGS = -w2 -c3 -i./include
LD ?= hlk
LDFLAGS =
CV = cv
LIB = lib
LIBFLAGS =

ifeq ($(findstring hlkx,$(LD)),hlkx)
USE_HLKX = true
endif

TARGET = zmsc3.x zmc.x zp3.r zpcnv3.r zplk3.r zsv.r zvt.x


.PHONY: all
.PRECIOUS: %.o

all: $(TARGET)

%.x: %.s
%.o: %.s
	$(AS) $(ASFLAGS) -sdebug=0 -o$@ $<
%.x %.fnc: %.o
	$(LD) $(LDFLAGS) -o$@ $<

ifdef USE_HLKX
%.r: %.o
	$(LD) $(LDFLAGS) -r --omit-bss -o$@ $<
else
%.r: %.x
	$(CV) $< $@
endif

ZMACROS = error.mac label.mac table.mac version.mac zmcall.mac zmd.mac zmid.mac z_global.mac

# -smpu=0%2
zmsc3.o: zmsc3.s pcm_read.s prterrms.s zmerrmes.s fopen.s work.s zmsc_int.s data_io.s \
         $(ZMACROS) dma.mac macro.mac

zmc.o: zmc.s include.s pcmproc.s zcerror.s fopen.s zcwork.s disprslt.s prterrms.s zmerrmes.s \
       $(ZMACROS) zclabel.mac zcmacro.mac

zp3.o: zp3.s embeddmy.s disprslt.s fopen.s \
       $(ZMACROS) common.mac zm_stat.mac

zpcnv3.o: zpcnv3.s pcmproc.s include.s pcm_read.s prterrms.s fopen.s zmerrmes.s \
       $(ZMACROS) zpcnv.mac

zplk3.o: zplk3.s fopen.s $(ZMACROS)

zsv.o: zsv.s fopen.s \
       $(ZMACROS) common.mac zm_stat.mac

zvt.o: zvt.s dma.mac


# EOF
