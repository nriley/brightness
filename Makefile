#!/usr/bin/env make -f
# Makefile to build brightness
# originally by Jon Stacey <jon@jonsview.com>

prefix=/usr/local

override CFLAGS += -mmacosx-version-min=10.6

all: build

build: brightness

brightness: brightness.o
	$(CC) $(CFLAGS) $(ARCH_FLAGS) -framework IOKit -framework ApplicationServices \
		-Wl,-U,_CGDisplayModeGetPixelWidth \
		-Wl,-U,_CGDisplayModeGetPixelHeight \
		$^ -o $@

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(ARCH_FLAGS) $< -c -o $@

clean:
	/bin/rm -f brightness *.o

install:
	/bin/mkdir -p $(prefix)/bin
	/usr/bin/install -s -m 0755 brightness $(prefix)/bin
