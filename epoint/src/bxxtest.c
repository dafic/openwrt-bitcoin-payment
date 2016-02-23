#include <stdio.h>
#include <string.h>
#include "b64.h"
#include "b32.h"
#include "b16.h"

static int check_enc(char *a, char *b, char *s,
 int (*enc)(const unsigned char *, int, char *, int)) {
	char buf[100];
	int n;
	int r = 0;

	n = enc((unsigned char *)a, strlen(a), buf, sizeof buf);
	if (n == -1 || strcmp(b, buf) != 0) {
		r++;
		printf("FAILED: %s %d enc(%s)->%s instead of %s\n", s, n, a, buf, b);
	}
	return r;
}

static int check_dec(char *a, char *b, char *s,
 int (*dec)(const char *, int, unsigned char *, int)) {
	char buf[100];
	int n;
	int r = 0;

	n = dec(b, strlen(b), (unsigned char *)buf, sizeof buf);
	if (n >= 0)
		buf[n] = 0;
	if (n == -1 || strcmp(a, buf) != 0) {
		r++;
		printf("FAILED: %s %d dec(%s)->%s instead of %s\n", s, n, b, buf, a);
	}
	return r;
}

int check64(char *a, char *b) {
	return check_enc(a, b, "b64", b64enc) +
	       check_dec(a, b, "b64", b64dec);
}

int check32(char *a, char *b) {
	return check_enc(a, b, "b32", b32enc);
}

int check16(char *a, char *b) {
	return check_enc(a, b, "b16", b16enc);
}

int main(void) {
	int r = 0;

	r += check64("", "");
	r += check64("a", "YQ==");
	r += check64("aa", "YWE=");
	r += check64("aaa", "YWFh");
	r += check64("aaaa", "YWFhYQ==");
	r += check64("xyz", "eHl6");
	r += check64("foobar", "Zm9vYmFy");
	r += check64("hello world", "aGVsbG8gd29ybGQ=");

	r += check32("", "");
	r += check32("a", "e6");
	r += check32("aa", "e7ii");
	r += check32("aaa", "e7iq4");
	r += check32("aaaa", "e7iq4sa");
	r += check32("xyz", "h3wrn");
	r += check32("foobar", "etrqysm3ga");
	r += check32("hello world", "f3kqsv5h63vqywmeei");

	r += check16("", "");
	r += check16("a", "jb");
	r += check16("aa", "jbjb");
	r += check16("aaa", "jbjbjb");
	r += check16("aaaa", "jbjbjbjb");
	r += check16("xyz", "kmknkp");
	r += check16("foobar", "jjjxjxjdjbkd");
	r += check16("hello world", "jmjhjtjtjxdakkjxkdjtjg");
	return r;
}
