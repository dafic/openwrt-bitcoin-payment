/* based on plan9 libc/port/u32.c */

#include "b32.h"

static char tab[] = "23456789abcdefghijkmnpqrstuvwxyz";

int b32enc(const unsigned char *in, int n, char *out, int nout) {
	char *start;
	int j;

	if (nout <= (8*n+4)/5)
		return -2;
	start = out;
	while (n >= 5) {
		j = (0x1f & (in[0]>>3));
		*out++ = tab[j];
		j = (0x1c & (in[0]<<2)) | (0x03 & (in[1]>>6));
		*out++ = tab[j];
		j = (0x1f & (in[1]>>1));
		*out++ = tab[j];
		j = (0x10 & (in[1]<<4)) | (0x0f & (in[2]>>4));
		*out++ = tab[j];
		j = (0x1e & (in[2]<<1)) | (0x01 & (in[3]>>7));
		*out++ = tab[j];
		j = (0x1f & (in[3]>>2));
		*out++ = tab[j];
		j = (0x18 & (in[3]<<3)) | (0x07 & (in[4]>>5));
		*out++ = tab[j];
		j = (0x1f & (in[4]));
		*out++ = tab[j];
		in  += 5;
		n -= 5;
	}
	if (n > 0) {
		j = (0x1f & (in[0]>>3));
		*out++ = tab[j];
		j = (0x1c & (in[0]<<2));
		if (n == 1)
			goto end;
		j |= (0x03 & (in[1]>>6));
		*out++ = tab[j];
		j = (0x1f & (in[1]>>1));
		*out++ = tab[j];
		j = (0x10 & (in[1]<<4));
		if (n == 2)
			goto end;
		j |= (0x0f & (in[2]>>4));
		*out++ = tab[j];
		j = (0x1e & (in[2]<<1));
		if (n == 3)
			goto end;
		j |= (0x01 & (in[3]>>7));
		*out++ = tab[j];
		j = (0x1f & (in[3]>>2));
		*out++ = tab[j];
		j = (0x18 & (in[3]<<3));
end:
		*out++ = tab[j];
	}
	*out = 0;
	return out - start;
}
