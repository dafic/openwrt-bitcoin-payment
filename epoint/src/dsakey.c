#include <stdlib.h>
#include <stdio.h>
#include <gcrypt.h>
#include "b64.h"

/*
multiuse rands are prefixed by "d" (ascii 0x64) to distinguish them
from regular rands, thus their length is of the form 4k + 1
("d" + base64(x) where x is the secret parameter of DSA)

In order to preempt the suspicion of weak DSA parameters,
we use the NIST method (FIPS 186-1) to generate them with

seed = 86108236b8526e296e923a4015b4282845b572cc
counter = 33
*/

static unsigned char p[] = {
0x9C, 0x05, 0xB2, 0xAA, 0x96, 0x0D, 0x9B, 0x97, 0xB8, 0x93, 0x19, 0x63, 0xC9, 0xCC, 0x9E, 0x8C,
0x30, 0x26, 0xE9, 0xB8, 0xED, 0x92, 0xFA, 0xD0, 0xA6, 0x9C, 0xC8, 0x86, 0xD5, 0xBF, 0x80, 0x15,
0xFC, 0xAD, 0xAE, 0x31, 0xA0, 0xAD, 0x18, 0xFA, 0xB3, 0xF0, 0x1B, 0x00, 0xA3, 0x58, 0xDE, 0x23,
0x76, 0x55, 0xC4, 0x96, 0x4A, 0xFA, 0xA2, 0xB3, 0x37, 0xE9, 0x6A, 0xD3, 0x16, 0xB9, 0xFB, 0x1C,
0xC5, 0x64, 0xB5, 0xAE, 0xC5, 0xB6, 0x9A, 0x9F, 0xF6, 0xC3, 0xE4, 0x54, 0x87, 0x07, 0xFE, 0xF8,
0x50, 0x3D, 0x91, 0xDD, 0x86, 0x02, 0xE8, 0x67, 0xE6, 0xD3, 0x5D, 0x22, 0x35, 0xC1, 0x86, 0x9C,
0xE2, 0x47, 0x9C, 0x3B, 0x9D, 0x54, 0x01, 0xDE, 0x04, 0xE0, 0x72, 0x7F, 0xB3, 0x3D, 0x65, 0x11,
0x28, 0x5D, 0x4C, 0xF2, 0x95, 0x38, 0xD9, 0xE3, 0xB6, 0x05, 0x1F, 0x5B, 0x22, 0xCC, 0x1C, 0x93};

static unsigned char q[] = {
0xA5, 0xDF, 0xC2, 0x8F, 0xEF, 0x4C, 0xA1, 0xE2, 0x86, 0x74, 0x4C, 0xD8, 0xEE, 0xD9, 0xD2, 0x9D,
0x68, 0x40, 0x46, 0xB7};

static unsigned char g[] = {
0x0C, 0x1F, 0x4D, 0x27, 0xD4, 0x00, 0x93, 0xB4, 0x29, 0xE9, 0x62, 0xD7, 0x22, 0x38, 0x24, 0xE0,
0xBB, 0xC4, 0x7E, 0x7C, 0x83, 0x2A, 0x39, 0x23, 0x6F, 0xC6, 0x83, 0xAF, 0x84, 0x88, 0x95, 0x81,
0x07, 0x5F, 0xF9, 0x08, 0x2E, 0xD3, 0x23, 0x53, 0xD4, 0x37, 0x4D, 0x73, 0x01, 0xCD, 0xA1, 0xD2,
0x3C, 0x43, 0x1F, 0x46, 0x98, 0x59, 0x9D, 0xDA, 0x02, 0x45, 0x18, 0x24, 0xFF, 0x36, 0x97, 0x52,
0x59, 0x36, 0x47, 0xCC, 0x3D, 0xDC, 0x19, 0x7D, 0xE9, 0x85, 0xE4, 0x3D, 0x13, 0x6C, 0xDC, 0xFC,
0x6B, 0xD5, 0x40, 0x9C, 0xD2, 0xF4, 0x50, 0x82, 0x11, 0x42, 0xA5, 0xE6, 0xF8, 0xEB, 0x1C, 0x3A,
0xB5, 0xD0, 0x48, 0x4B, 0x81, 0x29, 0xFC, 0xF1, 0x7B, 0xCE, 0x4F, 0x7F, 0x33, 0x32, 0x1C, 0x3C,
0xB3, 0xDB, 0xB1, 0x4A, 0x90, 0x5E, 0x7B, 0x2B, 0x3E, 0x93, 0xBE, 0x47, 0x08, 0xCB, 0xCC, 0x82};

typedef struct {
	gcry_mpi_t p;
	gcry_mpi_t q;
	gcry_mpi_t g;
	gcry_mpi_t y;
	gcry_mpi_t x;
} dsakey_t;

static void die(char *s) {
	fputs(s, stderr);
	exit(-1);
}

void init_gcry(void) {
	if (!gcry_check_version(GCRYPT_VERSION))
		die("libgcrypt initialization failed\n");
	gcry_control(GCRYCTL_DISABLE_SECMEM,0,0,0,0,0,0,0);
	gcry_control(GCRYCTL_INITIALIZATION_FINISHED);
}

static int getpgpmpi(gcry_mpi_t *m, unsigned char *buf, int n) {
	size_t siz;

	if (gcry_mpi_scan(m, GCRYMPI_FMT_PGP, buf, n, &siz))
		die("mpi_scan of pgp number failed\n");
	return siz;
}

static void getrawmpi(gcry_mpi_t *m, unsigned char *buf, int n) {
	if (gcry_mpi_scan(m, GCRYMPI_FMT_USG, buf, n, NULL))
		die("mpi_scan of raw number failed\n");
}

static int putpgpmpi(unsigned char *buf, int n, gcry_mpi_t m) {
	size_t siz;

	if (gcry_mpi_print(GCRYMPI_FMT_PGP, buf, n, &siz, m))
		die("mpi_print of pgp number failed\n");
	return siz;
}

static void puthexmpi(char *buf, int n, gcry_mpi_t m) {
	if (gcry_mpi_print(GCRYMPI_FMT_HEX, (unsigned char*)buf, n, 0, m))
		die("mpi_print of hex number failed\n");
}

/* md should be able to hold 20 bytes*/
static void sha(unsigned char *md, unsigned char *buf, int n) {
	gcry_md_hd_t h;
	unsigned char *p;

	gcry_md_open(&h, GCRY_MD_SHA1, 0);
	if (h == NULL)
		die("gcry_md_open failed\n");
	gcry_md_write(h, buf, n);
	gcry_md_final(h);
	p = gcry_md_read(h, 0);
	if (p == NULL)
		die("gcry_md_read failed\n");
	memcpy(md, p, 20);
	gcry_md_close(h);
}

static int putpubkey(unsigned char *buf, int n, gcry_mpi_t p, gcry_mpi_t q, gcry_mpi_t g, gcry_mpi_t y) {
	int i = 0;

	if (n < 10)
		die("not enough space for pgp packet.\n");
	buf[i++] = 4; /* version 4 */
	buf[i++] = 0; /* date */
	buf[i++] = 0;
	buf[i++] = 0;
	buf[i++] = 0;
	buf[i++] = 17; /* DSA */
	i += putpgpmpi(buf + i, n - i, p);
	i += putpgpmpi(buf + i, n - i, q);
	i += putpgpmpi(buf + i, n - i, g);
	i += putpgpmpi(buf + i, n - i, y);
	return i;
}

static int putseckey(unsigned char *buf, int n, gcry_mpi_t x) {
	int i, j, sum = 0;

	if (n < 1)
		die("not enough space for pgp packet.\n");
	buf[0] = 0; /* not encrypted */
	i = 1 + putpgpmpi(buf + 1, n - 1, x);
	for (j = 1; j < i; j++)
		sum += buf[j];
	if (n < i + 2)
		die("not enough space for pgp packet.\n");
	buf[i++] = sum >> 8; /* 2 byte checksum */
	buf[i++] = sum;
	return i;
}

dsakey_t *randtokey(char *rand) {
	unsigned char x[sizeof p];
	int n;
	dsakey_t *k = malloc(sizeof *k);

	if (!k)
		return NULL;
	if (rand[0] == 'd') {
		n = strlen(rand);
		if (rand[n-1] == '\n')
			n--;
		if (n%4 == 1)
			/* old style multiuse rand */
			rand++;
	}
	if ((n = b64dec(rand, strlen(rand), x, sizeof x)) <= 0) {
		free(k);
		return NULL;
	}
	getrawmpi(&k->p, p, sizeof p);
	getrawmpi(&k->q, q, sizeof q);
	getrawmpi(&k->g, g, sizeof g);
	getrawmpi(&k->x, x, n);
	k->y = gcry_mpi_new(1024);
	gcry_mpi_powm(k->y, k->g, k->x, k->p);
	return k;
}

dsakey_t *packettokey(unsigned char *buf, int n) {
	dsakey_t *k = malloc(sizeof *k);
	int i;
	int secret;

	if (!k)
		die("malloc failed\n");
	if (n < 9)
		die("short packet\n");
	if (buf[0] != 0x95 && buf[0] != 0x99)
		die("not cannonic secret or public key packet\n");
	secret = buf[0] == 0x95;
	if (buf[3] != 4)
		die("not version 4 packet\n");
	if (buf[8] != 17)
		die("not dsa key\n");
	i = 9;
	i += getpgpmpi(&k->p, buf + i, n - i);
	i += getpgpmpi(&k->q, buf + i, n - i);
	i += getpgpmpi(&k->g, buf + i, n - i);
	i += getpgpmpi(&k->y, buf + i, n - i);
	if (!secret) {
		k->x = 0;
		return k;
	}
	if (buf[i] != 0)
		die("secret key is encrypted\n");
	i++;
	i += getpgpmpi(&k->x, buf + i, n - i);
	return k;
}

void freekey(dsakey_t *k) {
	gcry_mpi_release(k->p);
	gcry_mpi_release(k->q);
	gcry_mpi_release(k->g);
	gcry_mpi_release(k->y);
	if (k->x)
		gcry_mpi_release(k->x);
	free(k);
}

void dumpkey(dsakey_t *k, FILE *f) {
	char buf[512];

	puthexmpi(buf, sizeof buf, k->p);
	fputs("p: ", f);
	fputs(buf, f);
	puthexmpi(buf, sizeof buf, k->q);
	fputs("\nq: ", f);
	fputs(buf, f);
	puthexmpi(buf, sizeof buf, k->g);
	fputs("\ng: ", f);
	fputs(buf, f);
	puthexmpi(buf, sizeof buf, k->y);
	fputs("\ny: ", f);
	fputs(buf, f);
	if (k->x) {
		puthexmpi(buf, sizeof buf, k->x);
		fputs("\nx: ", f);
		fputs(buf, f);
	}
	fputs("\n", f);
}

int pubkeypacket(unsigned char *buf, int n, dsakey_t *k) {
	int i;

	i = putpubkey(buf + 3, n - 3, k->p, k->q, k->g, k->y);
	buf[0] = 0x99; /* old packet format, public-key packet */
	buf[1] = i >> 8; /* 2 byte length */
	buf[2] = i;
	return i + 3;
}

int seckeypacket(unsigned char *buf, int n, dsakey_t *k) {
	int i;

	i = putpubkey(buf + 3, n - 3, k->p, k->q, k->g, k->y);
	i += putseckey(buf + 3 + i, n - 3 - i, k->x);
	buf[0] = 0x95; /* old packet format, secret-key packet */
	buf[1] = i >> 8; /* 2 byte length */
	buf[2] = i;
	return i + 3;
}

void fingerprint(unsigned char *md, dsakey_t *k) {
	unsigned char buf[4096];
	int n;

	n = pubkeypacket(buf, sizeof buf, k);
	sha(md, buf, n);
}
