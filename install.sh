#!/bin/sh

install -m 755 -d /usr/local/sbin
install -m 755 rpfload.pl /usr/local/sbin/rpfload
install -m 755 -d /usr/local/man/man8
install -m 644 rpfload.8 /usr/local/man/man8
