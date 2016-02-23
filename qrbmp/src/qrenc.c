/**
 * qrencode - QR Code encoder
 *
 * QR Code encoding tool
 * Copyright (C) 2006, 2007, 2008 Kentaro Fukuchi <fukuchi@megaui.net>
 *
 * BMP support by Daniel A. Nagy <nagydani@epointsystem.org>
 * Copyright (C) 2010 ePoint Systems Ltd.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <qrencode.h>

#define VERSION "3.0.3b"

static int casesensitive = 1;
static int eightbit = 0;
static int version = 0;
static int size = 3;
static int margin = 4;
static int structured = 0;
static QRecLevel level = QR_ECLEVEL_L;
static QRencodeMode hint = QR_MODE_8;

#define BMP_HEADER 0x3E

static unsigned char bmp_header[] = {
	0x42, 0x4D,          /* "BM" Magic Number */
	0, 0, 0, 0,          /* total size, LSB first */
	0, 0, 0, 0,          /* unused */
	BMP_HEADER, 0, 0, 0, /* bitmap offset */
	0x28, 0, 0, 0,       /* header bytes */
	0, 0, 0, 0,          /* width in pixels */
	0, 0, 0, 0,          /* height in pixels */
	1, 0,                /* 1 color plane */
	1, 0,                /* 1 bit/pixel */
	0, 0, 0, 0,          /* no compression */
	0, 0, 0, 0,          /* raw size */
	0x40, 0x1F, 0, 0,    /* 8000 pixel/meter horizontally */
	0x40, 0x1F, 0, 0,    /* 8000 pixel/meter vertically */
	0, 0, 0, 0,          /* no palette? */
	0, 0, 0, 0,          /* all colors are important */
	0, 0, 0, 0,          /* black */
	0xFF, 0xFF, 0xFF, 0  /* white */
};

#define BMP_SIZE 2
#define BMP_WIDTH 0x12
#define BMP_HEIGHT 0x16
#define BMP_RAW_SIZE 0x22

static void write_int(unsigned char *target, unsigned int value)
{
	int i = 4;
	while(i--) {
		target[i] = value >> (i << 3);
	}
}

static unsigned int line(unsigned int w) {
	return ((w + 0x1F) >> 3) & 0x1FFFFFFC;
}

static unsigned int total(unsigned int w, unsigned int h)
{
	return line(w) * h;
}

static const struct option options[] = {
	{"help"         , no_argument      , NULL, 'h'},
	{"output"       , required_argument, NULL, 'o'},
	{"level"        , required_argument, NULL, 'l'},
	{"size"         , required_argument, NULL, 's'},
	{"symversion"   , required_argument, NULL, 'v'},
	{"margin"       , required_argument, NULL, 'm'},
	{"structured"   , no_argument      , NULL, 'S'},
	{"kanji"        , no_argument      , NULL, 'k'},
	{"casesensitive", no_argument      , NULL, 'c'},
	{"ignorecase"   , no_argument      , NULL, 'i'},
	{"8bit"         , no_argument      , NULL, '8'},
	{"version"      , no_argument      , NULL, 'V'},
	{NULL, 0, NULL, 0}
};

static char *optstring = "ho:l:s:v:m:Skci8V";

static void usage(int help, int longopt)
{
	fprintf(stderr,
"qrbmp version %s\n"
"Copyright (C) 2006, 2007, 2008 Kentaro Fukuchi, 2010 ePoint Systems Ltd.\n", VERSION);
	if(help) {
		if(longopt) {
			fprintf(stderr,
"Usage: qrbmp [OPTION]... [STRING]\n"
"Encode input data in a QR Code and save as a BMP image.\n\n"
"  -h, --help   display the help message. -h displays only the help of short\n"
"               options.\n\n"
"  -o FILENAME, --output=FILENAME\n"
"               write BMP image to FILENAME. If '-' is specified, the result\n"
"               will be output to standard output. If -S is given, structured\n"
"               symbols are written to FILENAME-01.bmp, FILENAME-02.bmp, ...;\n"
"               if specified, remove a trailing '.bmp' from FILENAME.\n\n"
"  -s NUMBER, --size=NUMBER\n"
"               specify the size of dot (pixel). (default=3)\n\n"
"  -l {LMQH}, --level={LMQH}\n"
"               specify error collectin level from L (lowest) to H (highest).\n"
"               (default=L)\n\n"
"  -v NUMBER, --symversion=NUMBER\n"
"               specify the version of the symbol. (default=auto)\n\n"
"  -m NUMBER, --margin=NUMBER\n"
"               specify the width of margin. (default=4)\n\n"
"  -S, --structured\n"
"               make structured symbols. Version must be specified.\n\n"
"  -k, --kanji  assume that the input text contains kanji (shift-jis).\n\n"
"  -c, --casesensitive\n"
"               encode lower-case alphabet characters in 8-bit mode. (default)\n\n"
"  -i, --ignorecase\n"
"               ignore case distinctions and use only upper-case characters.\n\n"
"  -8, -8bit    encode entire data in 8-bit mode. -k, -c and -i will be ignored.\n\n"
"  -V, --version\n"
"               display the version number and copyrights of the qrencode.\n\n"
"  [STRING]     input data. If it is not specified, data will be taken from\n"
"               standard input.\n"
			);
		} else {
			fprintf(stderr,
"Usage: qrbmp [OPTION]... [STRING]\n"
"Encode input data in a QR Code and save as a BMP image.\n\n"
"  -h           display this message.\n"
"  --help       display the usage of long options.\n"
"  -o FILENAME  write BMP image to FILENAME. If '-' is specified, the result\n"
"               will be output to standard output. If -S is given, structured\n"
"               symbols are written to FILENAME-01.bmp, FILENAME-02.bmp, ...;\n"
"               if specified, remove a trailing '.bmp' from FILENAME.\n"
"  -s NUMBER    specify the size of dot (pixel). (default=3)\n"
"  -l {LMQH}    specify error collectin level from L (lowest) to H (highest).\n"
"               (default=L)\n"
"  -v NUMBER    specify the version of the symbol. (default=auto)\n"
"  -m NUMBER    specify the width of margin. (default=4)\n"
"  -S           make structured symbols. Version must be specified.\n"
"  -k           assume that the input text contains kanji (shift-jis).\n"
"  -c           encode lower-case alphabet characters in 8-bit mode. (default)\n"
"  -i           ignore case distinctions and use only upper-case characters.\n"
"  -8           encode entire data in 8-bit mode. -k, -c and -i will be ignored.\n"
"  -V           display the version number and copyrights of the qrencode.\n"
"  [STRING]     input data. If it is not specified, data will be taken from\n"
"               standard input.\n"
			);
		}
	}
}

#define MAX_DATA_SIZE (7090 * 16) /* from the specification */
static char *readStdin(void)
{
	char *buffer;
	int ret;

	buffer = (char *)malloc(MAX_DATA_SIZE);
	ret = fread(buffer, 1, MAX_DATA_SIZE, stdin);
	if(ret == 0) {
		fprintf(stderr, "No input data.\n");
		exit(1);
	}
	if(!feof(stdin)) {
		fprintf(stderr, "Input data is too large.\n");
		exit(1);
	}

	buffer[ret] = '\0';

	return buffer;
}

static int writeBMP(QRcode *qrcode, const char *outfile)
{
	FILE *fp;
	unsigned char *row, *p, *q;
	int x, y, xx, yy, bit;
	int realwidth;

	realwidth = (qrcode->width + margin * 2) * size;
	row = (unsigned char *)malloc(line(realwidth));
	if(row == NULL) {
		fprintf(stderr, "Failed to allocate memory.\n");
		exit(1);
	}

	if(outfile[0] == '-' && outfile[1] == '\0') {
		fp = stdout;
	} else {
		fp = fopen(outfile, "wb");
		if(fp == NULL) {
			fprintf(stderr, "Failed to create file: %s\n", outfile);
			perror(NULL);
			exit(1);
		}
	}

	write_int(&bmp_header[BMP_WIDTH], realwidth);
	write_int(&bmp_header[BMP_HEIGHT], realwidth);
	unsigned int raw_size = total(realwidth, realwidth);
	write_int(&bmp_header[BMP_RAW_SIZE], raw_size);
	write_int(&bmp_header[BMP_SIZE], raw_size + BMP_HEADER);
	fwrite(bmp_header, BMP_HEADER, 1, fp);

	/* bottom margin */
	memset(row, 0xff, line(realwidth));
	for(y=0; y<margin * size; y++) {
		fwrite(row, 1, line(realwidth), fp);
	}

	/* data */
	y = qrcode->width;
	while(y--) {
		p = &qrcode->data[y * qrcode->width];
		bit = 7;
		memset(row, 0xff, line(realwidth));
		q = row;
		q += margin * size / 8;
		bit = 7 - (margin * size % 8);
		for(x=0; x<qrcode->width; x++) {
			for(xx=0; xx<size; xx++) {
				*q ^= (*p & 1) << bit;
				bit--;
				if(bit < 0) {
					q++;
					bit = 7;
				}
			}
			p++;
		}
		for(yy=0; yy<size; yy++) {
			fwrite(row, 1, line(realwidth), fp);
		}
	}
	/* top margin */
	memset(row, 0xff, line(realwidth));
	for(y=0; y<margin * size; y++) {
		fwrite(row, 1, line(realwidth), fp);
	}

	fclose(fp);
	free(row);

	return 0;
}

static QRcode *encode(const char *intext)
{
	QRcode *code;

	if(eightbit) {
		code = QRcode_encodeString8bit(intext, version, level);
	} else {
		code = QRcode_encodeString(intext, version, level, hint, casesensitive);
	}

	return code;
}

static void qrencode(const char *intext, const char *outfile)
{
	QRcode *qrcode;
	
	qrcode = encode(intext);
	if(qrcode == NULL) {
		fprintf(stderr, "Failed to encode the input data.\n");
		exit(1);
	}
	writeBMP(qrcode, outfile);
	QRcode_free(qrcode);
}

static QRcode_List *encodeStructured(const char *intext)
{
	QRcode_List *list;

	if(eightbit) {
		list = QRcode_encodeString8bitStructured(intext, version, level);
	} else {
		list = QRcode_encodeStringStructured(intext, version, level, hint, casesensitive);
	}

	return list;
}

static void qrencodeStructured(const char *intext, const char *outfile)
{
	QRcode_List *qrlist, *p;
	char filename[FILENAME_MAX];
	char *base, *q, *suffix = NULL;
	int i = 1;

	base = strdup(outfile);
	if(base == NULL) {
		fprintf(stderr, "Failed to allocate memory.\n");
		exit(1);
	}
	if(strlen(base) > 4) {
		q = base + strlen(base) - 4;
		if(strcasecmp(".png", q) == 0) {
			suffix = strdup(q);
			*q = '\0';
		}
	}
	
	qrlist = encodeStructured(intext);
	if(qrlist == NULL) {
		fprintf(stderr, "Failed to encode the input data.\n");
		exit(1);
	}

	for(p = qrlist; p != NULL; p = p->next) {
		if(p->code == NULL) {
			fprintf(stderr, "Failed to encode the input data.\n");
			exit(1);
		}
		if(suffix) {
			snprintf(filename, FILENAME_MAX, "%s-%02d%s", base, i, suffix);
		} else {
			snprintf(filename, FILENAME_MAX, "%s-%02d", base, i);
		}
		writeBMP(p->code, filename);
		i++;
	}

	free(base);
	if(suffix) {
		free(suffix);
	}

	QRcode_List_free(qrlist);
}

int main(int argc, char **argv)
{
	int opt, lindex = -1;
	char *outfile = NULL;
	char *intext = NULL;

	while((opt = getopt_long(argc, argv, optstring, options, &lindex)) != -1) {
		switch(opt) {
			case 'h':
				if(lindex == 0) {
					usage(1, 1);
				} else {
					usage(1, 0);
				}
				exit(0);
				break;
			case 'o':
				outfile = optarg;
				break;
			case 's':
				size = atoi(optarg);
				if(size <= 0) {
					fprintf(stderr, "Invalid size: %d\n", size);
					exit(1);
				}
				break;
			case 'v':
				version = atoi(optarg);
				if(version < 0) {
					fprintf(stderr, "Invalid version: %d\n", version);
					exit(1);
				}
				break;
			case 'l':
				switch(*optarg) {
					case 'l':
					case 'L':
						level = QR_ECLEVEL_L;
						break;
					case 'm':
					case 'M':
						level = QR_ECLEVEL_M;
						break;
					case 'q':
					case 'Q':
						level = QR_ECLEVEL_Q;
						break;
					case 'h':
					case 'H':
						level = QR_ECLEVEL_H;
						break;
					default:
						fprintf(stderr, "Invalid level: %s\n", optarg);
						exit(1);
						break;
				}
				break;
			case 'm':
				margin = atoi(optarg);
				if(margin < 0) {
					fprintf(stderr, "Invalid margin: %d\n", margin);
					exit(1);
				}
				break;
			case 'S':
				structured = 1;
			case 'k':
				hint = QR_MODE_KANJI;
				break;
			case 'c':
				casesensitive = 1;
				break;
			case 'i':
				casesensitive = 0;
				break;
			case '8':
				eightbit = 1;
				break;
			case 'V':
				usage(0, 0);
				exit(0);
				break;
			default:
				fprintf(stderr, "Try `qrencode --help' for more information.\n");
				exit(1);
				break;
		}
	}

	if(argc == 1) {
		usage(1, 0);
		exit(0);
	}

	if(outfile == NULL) {
		fprintf(stderr, "No output filename is given.\n");
		exit(1);
	}

	if(optind < argc) {
		intext = argv[optind];
	}
	if(intext == NULL) {
		intext = readStdin();
	}

	if(structured) {
		if(version == 0) {
			fprintf(stderr, "Version must be specified to encode structured symbols.\n");
			exit(1);
		}
		qrencodeStructured(intext, outfile);
	} else {
		qrencode(intext, outfile);
	}

	return 0;
}
