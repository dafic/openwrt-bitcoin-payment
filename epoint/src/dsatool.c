#include <stdlib.h>
#include <stdio.h>
#include <gcrypt.h>
#include "dsakey.h"

static void die(char *s) {
	fputs(s, stderr);
	exit(-1);
}

int dsatool_main(int argc, char *argv[]) {
	unsigned char buf[4096];
	unsigned char md[20];
	char rand[1024];
	dsakey_t *k;
	int n;
	char cmd = 0;

	if (argc == 2 && argv[1][0] == '-')
		cmd = argv[1][1];
	if (cmd != 'f' && cmd != 'p' && cmd != 'a' && cmd != 's')
		die(
"usage: epoint_dsakey [-f|-p|-a|-s] < multiuse-rand > output\n"
" -f: fingerprint\n"
" -p: public-key packet\n"
" -a: armored public-key packet\n"
" -s: secret-key packet\n");

	if (fgets(rand, sizeof rand, stdin) == NULL)
		die("could not read multiuse-rand\n");

	init_gcry();
	k = randtokey(rand);
	if (!k)
		die("invalid rand\n");
	if (cmd == 'f') {
		fingerprint(md, k);
		for (n = 0; n < 20; n++)
			printf("%02X", md[n]);
		putchar('\n');
	}
	if (cmd == 'p') {
		n = pubkeypacket(buf, sizeof buf, k);
		fwrite(buf, 1, n, stdout);
	}
	if (cmd == 'a') {
		char s[4096];

		n = pubkeypacket(buf, sizeof buf, k);
		n = armor_buffer(s, sizeof s, buf, n, "PGP PUBLIC KEY BLOCK", "");
		if (n < 0)
			die("armoring failed\n");
		fwrite(s, 1, n, stdout);
	}
	if (cmd == 's') {
		n = seckeypacket(buf, sizeof buf, k);
		fwrite(buf, 1, n, stdout);
	}
	freekey(k);
	return 0;
}
