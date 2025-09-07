/*
 * Copyright (c) 2025 Brian Callahan <bcallah@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/stat.h>

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define INSIZE	8192
#define INSNLEN	8
#define LINELEN	64
#define REGLEN	32

static int
insn(const char *b)
{

	if (!strcmp(b, "movq") || !strcmp(b, "addq") ||
	    !strcmp(b, "subq") || !strcmp(b, "cmpq") ||
	    !strcmp(b, "xorq") || !strcmp(b, "andq") ||
	    !strcmp(b, "testq") || !strcmp(b, "orq") ||
	    !strcmp(b, "adcq") || !strcmp(b, "sbbq")) {
		return 'q';
	}

	if (!strcmp(b, "incq") || !strcmp(b, "rolq"))
		return 'r';

	if (!strcmp(b, "movl") || !strcmp(b, "addl") ||
	    !strcmp(b, "subl") || !strcmp(b, "cmpl") ||
	    !strcmp(b, "xorl") || !strcmp(b, "andl") ||
	    !strcmp(b, "testl") || !strcmp(b, "orl") ||
	    !strcmp(b, "cmovle") ||
	    !strcmp(b, "adcl") || !strcmp(b, "sbbl")) {
		return 'l';
	}

	if (!strcmp(b, "incl") || !strcmp(b, "roll"))
		return 'm';

	return 0;
}

static int
reg(const char *r, int t, char c)
{

	if (t == 'q') {
		if (c == 'b') {
			if (!strcmp(r, "%rbx"))
				return 'b';
			if (!strcmp(r, "%r11"))
				return 11;
		}

		if (c == 'a') {
			if (!strcmp(r, "%rax"))
				return 'a';
			if (!strcmp(r, "%r8"))
				return 8;
		}
	}

	if (t == 'l') {
		if (c == 'b') {
			if (!strcmp(r, "%ebx"))
				return 'b';
			if (!strcmp(r, "%r11d"))
				return 11;
		}

		if (c == 'a') {
			if (!strcmp(r, "%eax"))
				return 'a';
			if (!strcmp(r, "%r8d"))
				return 8;
		}
	}

	return 0;
}

static void
fixup(char *o, const char *s, size_t z)
{
	const char *p, *q;
	char i[INSNLEN], rd[REGLEN], rs[REGLEN];
	long n;
	int c, r, t, u = 0, v = 0;

	if (s[0] != '\t') {
		(void) strlcat(o, s, z);
		return;
	}

	p = s;
	++p;
	q = p;

	c = *p;
	while (c != '\t') {
		if (q - p > INSNLEN - 1) {
			(void) strlcat(o, s, z);
			return;
		}
		c = *++q;
	}

	n = q - p;
	(void) memcpy(i, p, n);
	i[n] = '\0';

	if ((t = insn(i)) == 0) {
		(void) strlcat(o, s, z);
		return;
	}

	p = ++q;

	if (t == 'r') {
		t = 'q';
		u = 1;
		goto solo;
	}

	if (t == 'm') {
		t = 'l';
		u = 1;
		goto solo;
	}

	if (*p != '%' && *p != '$') {
		(void) strlcat(o, s, z);
		return;
	}

	c = *p;
	while (c != ',') {
		if (q - p > REGLEN - 1) {
			(void) strlcat(o, s, z);
			return;
		}
		c = *++q;
	}

	n = q - p;
	(void) memcpy(rs, p, n);
	rs[n] = '\0';

	if (rs[0] == '$') {
		if (!strncmp(i, "cmp", 3)) {
			(void) strlcat(o, s, z);
			return;
		}
		v = 1;
	} else if (reg(rs, t, 'a') == 0) {
		(void) strlcat(o, s, z);
		return;
	}

	p = ++q;
	if (*p == ' ')
		p = ++q;

solo:
	if (*p != '%') {
		(void) strlcat(o, s, z);
		return;
	}

	c = *p;
	while (c != '\n') {
		if (q - p > REGLEN - 1) {
			(void) strlcat(o, s, z);
			return;
		}
		c = *++q;
	}

	n = q - p;
	(void) memcpy(rd, p, n);
	rd[n] = '\0';

	if ((r = reg(rd, t, 'b')) == 0) {
		(void) strlcat(o, s, z);
		return;
	}

	if (t == 'q')
		(void) strlcat(o, "\txchgq\t", z);
	else
		(void) strlcat(o, "\txchgl\t", z);

	(void) strlcat(o, rd, z);
	(void) strlcat(o, ", ", z);
	if (v) {
		if (t == 'q')
			(void) strlcat(o, "%rax", z);
		else
			(void) strlcat(o, "%eax", z);
	} else {
		(void) strlcat(o, rs, z);
	}
	(void) strlcat(o, "\n", z);

	(void) strlcat(o, "\t", z);
	(void) strlcat(o, i, z);
	(void) strlcat(o, "\t", z);

	if (v) {
		(void) strlcat(o, rs, z);
		(void) strlcat(o, ", ", z);
		u = 1;
	}

	if (t == 'q') {
		if (r == 'b') {
			if (!u)
				(void) strlcat(o, "%rbx, ", z);
			(void) strlcat(o, "%rax\n", z);
		} else {
			if (!u)
				(void) strlcat(o, "%r11, ", z);
			(void) strlcat(o, "%rax\n", z);
		}
	} else {
		if (r == 'b') {
			if (!u)
				(void) strlcat(o, "%ebx, ", z);
			(void) strlcat(o, "%eax\n", z);
		} else {
			if (!u)
				(void) strlcat(o, "%r11d, ", z);
			(void) strlcat(o, "%eax\n", z);
		}
	}

	if (t == 'q')
		(void) strlcat(o, "\txchgq\t", z);
	else
		(void) strlcat(o, "\txchgl\t", z);

	(void) strlcat(o, rd, z);
	(void) strlcat(o, ", ", z);
	if (v) {
		if (t == 'q')
			(void) strlcat(o, "%rax", z);
		else
			(void) strlcat(o, "%eax", z);
	} else {
		(void) strlcat(o, rs, z);
	}
	(void) strlcat(o, "\n", z);
}

int
main(int argc, char *argv[])
{
	struct stat sb;
	char *b, *o, *p = NULL, *p1, *s, *t = NULL;
	char buf[INSIZE], l[LINELEN];
	size_t y, z;
	long i = 0, n;
	int c, d = 0;

	for (c = 1; argv[c] != NULL; ++c) {
		if (!strcmp(argv[c], "-o")) {
			if (t)
				return 1;
			if (argv[++c] == NULL)
				return 1;
			t = argv[c];
		} else {
			if (i++)
				return 1;
			if (!strcmp(argv[c], "-"))
				continue;
			if ((d = open(argv[c], O_RDONLY)) == -1)
				return 1;
		}
	}

	if (d != 0) {
		if (fstat(d, &sb) == -1)
			return 1;

		if ((p = malloc(sb.st_size + 1)) == NULL)
			return 1;

		if (read(d, p, sb.st_size) != sb.st_size)
			return 1;
		p[sb.st_size] = '\0';

		(void) close(d);

		z = sb.st_size;
	} else {
		z = INSIZE;

		while ((n = read(d, buf, sizeof(buf) - 1)) > 0) {
			buf[n] = '\0';
			if ((p1 = malloc(z + 1)) == NULL)
				return 1;
			if (p != NULL) {
				(void) memcpy(p1, p, strlen(p));
				p1[strlen(p)] = '\0';
			} else {
				p1[0] = '\0';
			}
			(void) strlcat(p1, buf, z + 1);
			free(p);
			p = p1;
			z += INSIZE;
		}
	}

	if (t) {
		if ((d = open(t, O_RDWR | O_CREAT | O_TRUNC, 0644)) == -1) {
			free(p);
			p = NULL;
			return 1;
		}
	} else {
		d = 1;
	}

	z = (z + 1) << 2;
	if ((o = malloc(z)) == NULL) {
		free(p);
		p = NULL;
		return 1;
	}
	o[0] = '\0';

	b = p;

again:
	s = p;
	c = *p;
	while (c != '\n') {
		if (c == '\0')
			goto done;
		c = *++p;
	}
	++p;

	n = p - s;

	if (n > LINELEN) {
		for (i = 0; i < n; ++i) {
			y = 0;
			while (o[y] != '\0')
				++y;
			o[y++] = *(s + i);
			o[y] = '\0';
		}
	} else {
		(void) memcpy(l, s, n);
		l[n] = '\0';
		fixup(o, l, z);
	}

	goto again;

done:
	free(b);
	b = NULL;

	if (write(d, o, strlen(o)) != (ssize_t) strlen(o)) {
		free(o);
		o = NULL;
		return 1;
	}

	if (d != 1)
		(void) close(d);

	free(o);
	o = NULL;

	return 0;
}
