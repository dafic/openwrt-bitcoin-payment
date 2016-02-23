#include "b16.h"

static char tab[] = "abdeghjkmnpqtuwx";

int b16enc(const unsigned char *in, int n, char *out, int nout) {
	unsigned int c;
	char *start = out;

	if (nout <= 2*n)
		return -2;
	while (n-- > 0) {
		c = *in++;
		*out++ = tab[c>>4];
		*out++ = tab[c&0xf];
	}
	*out = 0;
	return out - start;
}
