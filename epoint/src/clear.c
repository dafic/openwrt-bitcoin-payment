/* OpenPGP signed cleartext, RFC 4880, 7 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <gcrypt.h>
#include "dsakey.h"
#include "cbio.h"
#include "clear.h"
#include "armor.h"

/* TODO: fix die("")s */

enum {
	lineLen = 1024,
	sigLen = 256
};

static void die(char *s) {
	fputs(s, stderr);
	exit(-1);
}

static void canonline(char *buf) {
	int i;

	for (i = strlen(buf) - 1; i >= 0; i--) {
		if (buf[i] != ' ' && buf[i] != '\t' && buf[i] != '\r' && buf[i] != '\n')
			break;
	}
	buf[i+1] = '\r';
	buf[i+2] = '\n';
	buf[i+3] = '\0';
}

static void dashescline(char *buf) {
	int n = strlen(buf);

	buf[n-2] = '\n';
	buf[n-1] = '\0';
	if (buf[0] == '-') {
		memmove(buf + 2, buf, n);
		buf[1] = ' ';
	}
}

static int putpgpmpi(unsigned char *buf, int n, gcry_mpi_t m) {
	size_t siz;

	if (gcry_mpi_print(GCRYMPI_FMT_PGP, buf, n, &siz, m))
		die("mpi_print of pgp number failed\n");
	return siz;
}

static void sign(gcry_mpi_t *r, gcry_mpi_t *s, gcry_mpi_t hash, dsakey_t *k) {
	gcry_sexp_t key;
	gcry_sexp_t data;
	gcry_sexp_t sig;
	gcry_sexp_t tmp;

	if (gcry_sexp_build(&key, 0, "(private-key(dsa(p%m)(q%m)(g%m)(y%m)(x%m)))",
	  k->p, k->q, k->g, k->y, k->x))
		die("key sexp_build failed\n");
	if (gcry_sexp_build(&data, 0, "(data (flags raw)(value %m))", hash))
		die("data sexp_build failed\n");

	if (gcry_pk_sign(&sig, data, key))
		die("pk_sign failed\n");

	tmp = gcry_sexp_find_token (sig, "sig-val", 0);
	if (!tmp)
		die("no sig-val found in sig\n");
	gcry_sexp_release(sig);
	sig = tmp;
	tmp = gcry_sexp_find_token(sig, "dsa", 0);
	if (!tmp)
		die("no dsa found in sig\n");
	gcry_sexp_release(sig);
	sig = tmp;
	tmp = gcry_sexp_find_token(sig, "r", 0);
	if (!tmp)
		die("no r found in sig\n");
	*r = gcry_sexp_nth_mpi(tmp, 1, GCRYMPI_FMT_USG);
	if (!r)
		die("could not decode r from sig\n");
	gcry_sexp_release(tmp);
	tmp = gcry_sexp_find_token(sig, "s", 0);
	if (!tmp)
		die("no s found in sig\n");
	*s = gcry_sexp_nth_mpi(tmp, 1, GCRYMPI_FMT_USG);
	if (!s)
		die("could not decode s from sig\n");
	gcry_sexp_release(tmp);
	gcry_sexp_release(sig);
	gcry_sexp_release(key);
	gcry_sexp_release(data);
}

int clearsign(int (*wc)(int, void *), void *wd, int (*rc)(void *), void *rd, dsakey_t *k) {
	gcry_md_hd_t md;
	gcry_mpi_t h;
	gcry_mpi_t r;
	gcry_mpi_t s;
	unsigned char *hash;
	unsigned char data[sigLen];
	char buf[4096];
	int n;
	unsigned int t = time(0);

	gcry_md_open(&md, GCRY_MD_SHA1, 0);
	if (md == NULL)
		die("gcry_md_open failed\n");

	cbputs("-----BEGIN PGP SIGNED MESSAGE-----\n", wc, wd);
	cbputs("Hash: SHA1\n\n", wc, wd);
	while (cbgets(buf, lineLen, rc, rd)) {
		canonline(buf);
		gcry_md_write(md, buf, strlen(buf));
		dashescline(buf);
		cbputs(buf, wc, wd);
	}
	if (wc('\n', wd) < 0)
		return -1;

	/* creating signature */
	data[0] = 4; /* version 4 */
	data[1] = 1; /* text signature */
	data[2] = 17; /* dsa */
	data[3] = 2; /* SHA1 */
	data[4] = 0;
	data[5] = 6; /* hashed subpackets len */
	data[6] = 5;
	data[7] = 2; /* creation time subpacket */
	data[8] = t >> 24;
	data[9] = t >> 16;
	data[10] = t >> 8;
	data[11] = t;
	data[12] = 4; /* extra mess going into the hash */
	data[13] = 0xff;
	data[14] = 0;
	data[15] = 0;
	data[16] = 0;
	data[17] = 12;
	gcry_md_write(md, data, 18);
	gcry_md_final(md);
	hash = gcry_md_read(md, 0);
	if (hash == NULL)
		die("gcry_md_read failed\n");
	data[12] = 0;
	data[13] = 10; /* unhashed subpacket len */
	data[14] = 9;
	data[15] = 16; /* issuer id subpacket */
	fingerprint(data+16, k);
	memmove(data+16, data+16+12, 8); /* we only use the last 8 bytes */
	data[24] = hash[0];
	data[25] = hash[1];
	n = 26;
	if (gcry_mpi_scan(&h, GCRYMPI_FMT_USG, hash, 20, 0))
		die("hash mpi_scan failed\n");
	sign(&r, &s, h, k);
	gcry_md_close(md);
	n += putpgpmpi(data + n, sigLen - n, r);
	n += putpgpmpi(data + n, sigLen - n, s);
	if (n > 250)
		die("signature packet is too large\n");
	memmove(data + 2, data, n);
	data[0] = 0x88; /* signature packet with old style length */
	data[1] = n;
	if (armor_buffer(buf, sizeof buf, data, n + 2, "PGP SIGNATURE", "") < 0)
		die("armoring signature failed\n");
	if (cbputs(buf, wc, wd) < 0)
		return -1;
	gcry_mpi_release(r);
	gcry_mpi_release(s);
	gcry_mpi_release(h);
	return 0;
}

int clearsign_stream(FILE *out, FILE *in, dsakey_t *k) {
	return clearsign(putc_stream, out, getc_stream, in, k);
}

int clearsign_buffer(char *dst, int ndst, char *src, int nsrc, dsakey_t *k) {
	unsigned char *udst = (void*)dst;
	unsigned char *usrc = (void*)src;
	buffer_t dstbuf = {udst, udst + ndst};
	buffer_t srcbuf = {usrc, usrc + nsrc};

	if (clearsign(putc_buffer, &dstbuf, getc_buffer, &srcbuf, k) < 0 ||
	  dstbuf.p == udst)
		return -1;
	*dstbuf.p = '\0';
	return dstbuf.p - udst;
}
