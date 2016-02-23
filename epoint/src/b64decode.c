/*  Very basic base64 decoder. */

#include <stdio.h>
#include "b64.h"

int b64decode_main(int argc, char *argv[]) {
	char in[500];
	unsigned char out[sizeof in];
	int outlen;

	if (fgets(in, sizeof in, stdin) == NULL)
		return -1;
	outlen = b64dec(in, sizeof in, out, sizeof out);
	if (outlen < 0) {
		fprintf(stderr, "%s: invalid base64 sequence.\n", argv[0]);
		return -1;
	}
	fwrite(out, 1, outlen, stdout);
	return 0;
}
