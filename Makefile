# rop Makefile

CC ?=		cc
CFLAGS ?=	-O2 -pipe

PROG =	rop
OBJS =	rop.o

all: ${OBJS}
	${CC} ${LDFLAGS} -o ${PROG} ${OBJS}

#.c.o:
#	${CC} ${CFLAGS} ${CPPFLAGS} -o- -S $< | rop | ${CC} -o $@ -c -x assembler -

clean:
	rm -f ${PROG} ${OBJS} ${PROG}.core
