#!/usr/bin/env make -f
# Makefile to build brightness
# originally by Jon Stacey <jon@jonsview.com>

prefix=/usr/local

override CFLAGS += -mmacosx-version-min=10.8

all: build

build: brightness

brightness: brightness.o
	$(CC) $(CFLAGS) $(ARCH_FLAGS) \
		-framework IOKit \
		-framework ApplicationServices \
		-framework CoreDisplay \
		-F /System/Library/PrivateFrameworks \
		-framework DisplayServices \
		-Wl,-U,_CoreDisplay_Display_SetUserBrightness \
		-Wl,-U,_CoreDisplay_Display_GetUserBrightness \
		-Wl,-U,_DisplayServicesCanChangeBrightness \
		-Wl,-U,_DisplayServicesBrightnessChanged \
		$^ -o $@

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(ARCH_FLAGS) $< -c -o $@

clean:
	/bin/rm -f brightness *.o

install:
	/bin/mkdir -p $(prefix)/bin
	/usr/bin/install -s -m 0755 brightness $(prefix)/bin
