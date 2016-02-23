#include <stdio.h>
#include "cbio.h"

int getc_stream(void *rd) {
	FILE *f = rd;

	return getc(f);
}

int putc_stream(int c, void *wd) {
	FILE *f = wd;

	return putc(c, f);
}

int getc_buffer(void *rd) {
	buffer_t *buf = rd;

	if (buf->p == buf->e)
		return -1;
	return *buf->p++;
}

int putc_buffer(int c, void *wd) {
	buffer_t *buf = wd;

	if (buf->p == buf->e)
		return -1;
	return *buf->p++ = c;
}

char *cbgets(char *s, int n, int (*rc)(void *), void *rd) {
	unsigned char *p = (unsigned char *)s;
	int c;

	while (--n > 0 && (c = rc(rd)) >= 0) {
		*p++ = c;
		if (c == '\n')
			break;
	}
	if (c < 0 && p == (unsigned char*)s)
		return 0;
	*p++ = '\0';
	return s;
}

int cbputs(char *s, int (*wc)(int, void *), void *wd) {
	int c;

	while ((c = *s++))
		if ((c = wc(c, wd)) < 0)
			break;
	return c;
}
