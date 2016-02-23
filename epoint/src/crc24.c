/* CRC-24 according to RFC 4880, section 6.1 */

#include "armor.h"

enum {
	crcInit = 0xb704ce,
	crcPoly = 0x1864cfb
};

unsigned crc24init(void) {
	return crcInit;
}

unsigned crc24update(unsigned crc, unsigned char *data, unsigned len) {
	int i, j;

	for (i = 0; i < len; i++) {
		crc ^= data[i] << 16;
		for (j = 0; j < 8; j++) {
			crc <<= 1;
			if (crc & 0x1000000)
				crc ^= crcPoly;
		}
	}
	return crc;
}

unsigned crc24end(unsigned crc) {
	return crc & 0xffffff;
}
