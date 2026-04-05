opt
===
`opt` is a utility that can act as an optimization pass for
[GCC](https://gcc.gnu.org/)
to remove potential polymorphic ROP gadgets on 32-bit and
64-bit x86 CPUs.

`opt` is conceptually similar to an
[LLVM](https://llvm.org/)
[fixup pass](https://github.com/openbsd/src/blob/master/gnu/llvm/llvm/lib/Target/X86/X86FixupGadgets.cpp)
pioneered by Todd Mortimer (mortimer@) in
[OpenBSD](https://www.openbsd.org/)
as
[presented](https://www.openbsd.org/papers/asiabsdcon2019-rop-slides.pdf#page=46.00)
at
[AsiaBSDCon 2019](https://www.openbsd.org/papers/asiabsdcon2019-rop-paper.pdf)
and the `-mmitigate-rop` flag that used to exist in GCC.

Building
--------
`opt` is written in
[D](https://dlang.org/).
The `configure` script will find a suitable D compiler
automatically.

```sh
$ ./configure
$ make
$ sudo make install
```

Usage
-----
You can modify your make rules to insert an invocation of
`opt` in the appropriate place.

For example, for C files:
```make
.c.o:
	${CC} ${CFLAGS} ${CPPFLAGS} -o- -S $< | opt | ${CC} -o $@ -c -x assembler -
```

Alternatively, you must modify your copy of GCC to insert
an invocation of `opt` between the output of the compiler
pass (`cc1`, `cc1plus`, etc.) and the assembler. A patch to
do that for GCC 15.2.0 is
[available](https://github.com/ibara/rop/blob/main/gcc_cc.diff).

GCC 15.2.0 is able to complete a 3-stage compiler build of
itself on FreeBSD/amd64 15.0-RELEASE with `opt` having appiled
the above patch using the following compiler invocation:
```sh
../gcc-15.2.0/configure --prefix=/opt/rop --enable-languages=c,c++,d --with-included-gettext --with-as=/usr/local/bin/as --with-ld=/usr/local/bin/ld --enable-gnu-indirect-function --disable-libssp --disable-multilib
```

LICENSE
-------
ISC License. See `LICENSE` for more information.
