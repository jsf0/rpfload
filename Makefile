PROG=	rpfload
MAN=	rpfload.8

install:
	install -o root -g bin ${PROG}.pl /usr/local/sbin/${PROG}
	install -o root -g bin -m 644 ${MAN} /usr/local/man/man8
	makewhatis /usr/local/man

# check for errors in the manual
man:
	mandoc -Tlint ${MAN}
