# Makefile for MUSICZ3.FNC

AS = has060
ASFLAGS = -w2 -c3 -i../ -i../include
LD ?= hlk
LDFLAGS =

TARGET = musicz3.fnc


.PHONY: all
.PRECIOUS: %.o

all: $(TARGET)

%.o: %.s
	$(AS) $(ASFLAGS) -sdebug=0 -o$@ $<
%.fnc: %.o
	$(LD) $(LDFLAGS) -o$@ $<


# EOF
