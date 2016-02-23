/* ASCII Armor according to RFC 4880, section 6.2 */

#include <stdio.h>
#include "cbio.h"
#include "b64.h"
#include "armor.h"

/*
-----BEGIN <heading>-----
<headers>

base64 encoded text split into armorLine length lines
=<crc24>
-----END <heading>-----
*/

enum {
	armorLine = 64,
	srcLine = armorLine*3/4
};

int armor(int (*wc)(int, void *), void *wd, int (*rc)(void *), void *rd, char *heading, char *headers) {
	char buf[1024];
	unsigned char line[srcLine];
	unsigned crc;
	unsigned char crcbytes[3];
	int n;
	int i;
	int c;

	n = snprintf(buf, sizeof buf, "-----BEGIN %s-----\n%s\n", heading, headers);
	if (n < 0 || n >= sizeof buf)
		return -1;
	if (cbputs(buf, wc, wd) < 0)
		return -1;
	crc = crc24init();
	for (;;) {
		for (i = 0; i < sizeof line; i++) {
			c = rc(rd);
			if (c < 0)
				break;
			line[i] = c;
		}
		if (i > 0) {
			crc = crc24update(crc, line, i);
			n = b64enc(line, i, buf, sizeof buf);
			buf[n] = '\n';
			buf[n+1] = '\0';
			if (cbputs(buf, wc, wd) < 0)
				return -1;
		}
		if (i < sizeof line)
			break;
	}
	crc = crc24end(crc);
	crcbytes[0] = crc >> 16;
	crcbytes[1] = crc >> 8;
	crcbytes[2] = crc;
	buf[0] = '=';
	b64enc(crcbytes, 3, buf+1, 5);
	n = snprintf(buf+5, sizeof buf - 5, "\n-----END %s-----\n", heading);
	if (n < 0 || n >= sizeof buf - 5)
		return -1;
	if (cbputs(buf, wc, wd) < 0)
		return -1;
	return 0;
}

int armor_buffer(char *dst, int ndst, unsigned char *src, int nsrc, char *heading, char *headers) {
	unsigned char *udst = (void*)dst;
	buffer_t dstbuf = {udst, udst + ndst};
	buffer_t srcbuf = {src, src + nsrc};

	if (armor(putc_buffer, &dstbuf, getc_buffer, &srcbuf, heading, headers) < 0 ||
	  dstbuf.p == udst)
		return -1;
	*dstbuf.p = '\0';
	return dstbuf.p - udst;
}
