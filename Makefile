#!/usr/bin/env make -f
# Makefile to build brightness
# Friday November 1, 2013
# Jon Stacey <jon@jonsview.com>

prefix=/usr/local

all: build

build: brightness

brightness: brightness.o
	$(CC) $(CPPFLAGS) $(CFLAGS) $(ARCH_FLAGS) -framework IOKit -framework ApplicationServices $^ -o $@

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(ARCH_FLAGS) $< -c -o $@

clean:
	/bin/rm -f brightness *.o

install:
	/bin/mkdir -p $(prefix)/bin
	/usr/bin/install -s -m 0755 brightness $(prefix)/bin

