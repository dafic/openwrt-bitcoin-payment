/* based on plan9 libc/port/u64.c */

#include "b64.h"

enum {
	BASE = 64,
	WS  = 253,
	END = 254,
	BAD = 255
};

static unsigned char tabdec[256] = {
/*  0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15 */
  END,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD, WS, WS,BAD,BAD, WS,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
   WS,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD, 62,BAD,BAD,BAD, 63,
   52, 53, 54, 55, 56, 57, 58, 59, 60, 61,BAD,BAD,BAD,END,BAD,BAD,
  BAD,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
   15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,BAD,BAD,BAD,BAD,BAD,
  BAD, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
   41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
  BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD
};

static char tabenc[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

int b64dec(const char *in, int n, unsigned char *out, int nout) {
	unsigned int b24;
	unsigned char *start = out;
	unsigned char *e = out + nout;
	int i, c;

	b24 = 0;
	i = 0;
	while (n-- > 0) {
		c = tabdec[*(unsigned char*)in++];
		if (c >= BASE) {
			if (c == WS)
				continue;
			/* Note: '=' or '\0' is considered as eof
			   padding is not checked */
			if (c == END)
				break;
			if (c == BAD)
				return -1;
		}
		switch (i) {
		case 0:
			b24 = c<<18;
			break;
		case 1:
			b24 |= c<<12;
			break;
		case 2:
			b24 |= c<<6;
			break;
		case 3:
			if (out + 3 > e)
				return -2;
			b24 |= c;
			*out++ = b24>>16;
			*out++ = b24>>8;
			*out++ = b24;
			i = -1;
			break;
		}
		i++;
	}
	switch (i) {
	case 1:
		return -1;
	case 2:
		if (out + 1 > e)
			return -2;
		*out++ = b24>>16;
		break;
	case 3:
		if(out + 2 > e)
			return -2;
		*out++ = b24>>16;
		*out++ = b24>>8;
		break;
	}
	return out - start;
}

int b64enc(const unsigned char *in, int n, char *out, int nout) {
	int i;
	unsigned int b24;
	char *start = out;
	char *e = out + nout;

	for (i = n/3; i > 0; i--) {
		b24 = (*in++)<<16;
		b24 |= (*in++)<<8;
		b24 |= *in++;
		if (out + 4 >= e)
			return -2;
		*out++ = tabenc[(b24>>18)];
		*out++ = tabenc[(b24>>12)&0x3f];
		*out++ = tabenc[(b24>>6)&0x3f];
		*out++ = tabenc[(b24)&0x3f];
	}
	switch (n%3) {
	case 2:
		b24 = (*in++)<<16;
		b24 |= (*in)<<8;
		if (out + 4 >= e)
			return -2;
		*out++ = tabenc[(b24>>18)];
		*out++ = tabenc[(b24>>12)&0x3f];
		*out++ = tabenc[(b24>>6)&0x3f];
		*out++ = '=';
		break;
	case 1:
		b24 = (*in)<<16;
		if (out + 4 >= e)
			return -2;
		*out++ = tabenc[(b24>>18)];
		*out++ = tabenc[(b24>>12)&0x3f];
		*out++ = '=';
		*out++ = '=';
		break;
	}
	*out = 0;
	return out - start;
}
