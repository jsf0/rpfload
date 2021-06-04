#!/bin/sh

install -m 755 -d /usr/local/bin
install -m 755 rpfload.pl /usr/local/bin/rpfload
install -m 755 -d /usr/local/man/man1
install -m 644 rpfload.1 /usr/local/man/man1
