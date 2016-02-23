#include <stdlib.h>
#include <stdio.h>
#include <gcrypt.h>
#include "dsakey.h"
#include "clear.h"

int sign_main(int argc, char *argv[]) {
	dsakey_t *k;

	if (argc != 2) {
		fprintf(stderr, "usage: epoint_sign multiuse_rand <document >signeddoc\n");
		return 1;
	}

	init_gcry();
	k = randtokey(argv[1]);
	if (!k) {
		fprintf(stderr, "invalid rand\n");
		return 1;
	}
	clearsign_stream(stdout, stdin, k);
	freekey(k);
	return 0;
}
