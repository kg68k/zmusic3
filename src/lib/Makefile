# Makefile for ZMSC3LIB

AS = has060
ASFLAGS = -w2 -c2 -i../ -i../include
AR = oar
ARFLAGS = -c

#TARGET = libzmsc3.a
TARGET = ZMSC3LIB.A ZMSC3LIB.L

SRCS = $(wildcard *.s)
OBJS = $(SRCS:.s=.o)


.PHONY: all
.PRECIOUS: %.o

all: $(TARGET)

%.o: %.s
	$(AS) $(ASFLAGS) -o$@ $<

libzmsc3.a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

ZMSC3LIB.A: $(SRCS) $(wildcard debris/*.s)
	cp -ufU $^ zmsc3lib_a
	make -Czmsc3lib_a

ZMSC3LIB.L: $(SRCS) $(wildcard debris/*.s)
	cp -ufU $^ zmsc3lib_l
	make -Czmsc3lib_l


# EOF
