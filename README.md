rop
===
`rop` is a utility that can act as an optimization pass for
[GCC](https://gcc.gnu.org/)
to remove potential polymorphic ROP gadgets on 32-bit and
64-bit x86 CPUs.

`rop` is conceptually similar to an
[LLVM](https://llvm.org/)
[fixup pass](https://github.com/openbsd/src/blob/master/gnu/llvm/llvm/lib/Target/X86/X86FixupGadgets.cpp)
pioneered by Todd Mortimer (mortimer@) in
[OpenBSD](https://www.openbsd.org/)
as
[presented](https://www.openbsd.org/papers/asiabsdcon2019-rop-slides.pdf#page=46.00)
at AsiaBSDCon 2019.

Building
--------
```sh
$ make
```
or
```sh
$ make CC=gcc
```
to use a C compiler of your specification.

Usage
-----
You can modify your make rules to insert an invocation of
`rop` in the appropriate place.

For example, for C files:
```make
.c.o:
	${CC} ${CFLAGS} ${CPPFLAGS} -o- -S $< | rop | ${CC} -o $@ -c -x assembler -
```

Alternatively, you must modify your copy of GCC to insert
an invocation of `rop` between the output of the compiler
pass (`cc1`, `cc1plus`, etc.) and the assembler.

LICENSE
-------
ISC License. See `LICENSE` for more information.
