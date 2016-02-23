/**
 * barcode - barcode png encoder
 *
 * Copyright (C) 2009 ePoint Systems Ltd.
 *
 * Losely based on Kentaro Fukuchi's libqrencode
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <png.h>
#include <getopt.h>

#include "code128font.c"

#define VERSION "0.1"

static const struct option options[] = {
	{"help"         , no_argument      , NULL, 'h'},
	{"rotate"	, no_argument      , NULL, 'r'},
	{"output"       , required_argument, NULL, 'o'},
	{"size"         , required_argument, NULL, 's'},
	{"margin"       , required_argument, NULL, 'm'},
	{"height"       , required_argument, NULL, 't'},
	{"version"      , no_argument      , NULL, 'v'},
	{NULL, 0, NULL, 0}
};

static char *optstring = "hro:s:m:t:v";

static void usage(int help)
{
	fprintf(stderr,
"barcode version %s\n"
"Copyright (C) 2009 ePoint Systems Ltd.\n", VERSION);
	if(help) {
			fprintf(stderr,
"Usage: barcode [OPTION]... [STRING]\n"
"Save barcode as a PNG image.\n\n"
"  -h, --help   display the help message.\n\n"
"  -o FILENAME, --output=FILENAME\n"
"               write PNG image to FILENAME. If '-' is specified, the result\n"
"               will be output to standard output.\n"
"  -s NUMBER, --size=NUMBER\n"
"               specify the size of module (unit bar). (default=2)\n\n"
"  -r, --rotate rotate the barcode to vertical position. (by 90 degrees)\n\n"
"  -m NUMBER, --margin=NUMBER\n"
"               specify the width of margin. (default=10)\n\n"
"  -t NUMBER, --height=NUMBER\n"
"               specify the height of the barcode (default=20)\n\n"
"  -v, --version\n"
"               display the version number and copyrights of the qrencode.\n\n"
"  [STRING]     input data. If it is not specified, data will be taken from\n"
"               standard input.\n"
			);
	}
}

#define MAX_DATA_SIZE (1024)
static char buffer[MAX_DATA_SIZE + 1];

static int size = 2, margin = 10, height = 20, vertical = 0;

static char *readStdin(void)
{
	int ret;

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

static int writePNG(char* barcode, const char *outfile)
{
	FILE *fp;
	png_structp png_ptr;
	png_infop info_ptr;
	unsigned char *p, *q;
	int c, m, s;
	int x, y, xx, yy, bit;
	int width = strlen(barcode);
	int realwidth = ((width + 3) * 11 + 2 + margin * 2) * size;
	unsigned char row[((vertical ? height : realwidth) + 7) >> 3];

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

	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if(png_ptr == NULL) {
		fclose(fp);
		fprintf(stderr, "Failed to initialize PNG writer.\n");
		exit(1);
	}

	info_ptr = png_create_info_struct(png_ptr);
	if(info_ptr == NULL) {
		fclose(fp);
		fprintf(stderr, "Failed to initialize PNG write.\n");
		exit(1);
	}

	if(setjmp(png_jmpbuf(png_ptr))) {
		png_destroy_write_struct(&png_ptr, &info_ptr);
		fclose(fp);
		fprintf(stderr, "Failed to write PNG image.\n");
		exit(1);
	}

	png_init_io(png_ptr, fp);
	png_set_IHDR(png_ptr, info_ptr,
			vertical ? height : realwidth,
			vertical ? realwidth : height,
			1,
			PNG_COLOR_TYPE_GRAY,
			PNG_INTERLACE_NONE,
			PNG_COMPRESSION_TYPE_DEFAULT,
			PNG_FILTER_TYPE_DEFAULT);
	png_write_info(png_ptr, info_ptr);

	/* data */
	p = barcode;
	s = START_B;
	c = code128font[s];
	m = 0x400;
	bit = 7;
	memset(row, 0xff, ((vertical ? height : realwidth) + 7) >> 3);
	if(vertical) {
		x = margin * size;
		while(x-- > 0) png_write_row(png_ptr, row);
	} else {
		q = row;
		q += (margin * size) >> 3;
		bit = 7 - (margin * size % 8);
	}
	for(x = -1; x <= width;) {
		if(vertical) {
			memset(row, (c & m) ? 0 : 0xFF, (height + 7) >> 3);
			xx = size;
			while(xx-- > 0) png_write_row(png_ptr, row);
		} else {
			for(xx = 0; xx < size; xx++) {
				*q ^= ((c & m) ? 1 : 0) << bit;
				bit--;
				if(bit < 0) {
					q++;
					bit = 7;
				}
			}
		}
		m >>= 1;
		if(!m) {
			x++;
			if(*p) {
				if((*p < ' ') || (*p & 0x80)) {
					c = code128font[0];
				} else {
					c = code128font[*p - ' '];
					s += (*p - ' ') * (x + 1);
					s %= 103;
				}
				m = 0x400;
			} else {
				c = code128font[s] << 13 |
				    code128font[STOP] << 2 | 3;
				m = 0x800000;
			}
			p++;
		}
	}
	if(vertical) {
		memset(row, 0xFF, (height + 7) >> 3);
		x = margin * size;
		while(x-- > 0) png_write_row(png_ptr, row);
	} else {
		for(y = 0; y < height; y++) {
			png_write_row(png_ptr, row);
		}
	}

	png_write_end(png_ptr, info_ptr);
	png_destroy_write_struct(&png_ptr, &info_ptr);

	fclose(fp);

	return 0;
}

int main(int argc, char **argv)
{
	int opt, lindex = -1;
	char *outfile = NULL;
	char *intext = NULL;

	while((opt = getopt_long(argc, argv, optstring, options, &lindex)) != -1) {
		switch(opt) {
			case 'h':
				usage(1);
				exit(0);
				break;
			case 'o':
				outfile = optarg;
				break;
			case 'r':
				vertical = -1;
				break;
			case 's':
				size = atoi(optarg);
				if(size <= 0) {
					fprintf(stderr, "Invalid size: %d\n", size);
					exit(1);
				}
				break;
			case 'm':
				margin = atoi(optarg);
				if(margin < 0) {
					fprintf(stderr, "Invalid margin: %d\n", margin);
					exit(1);
				}
				break;
			case 't':
				height = atoi(optarg);
				if(height < 1) {
					fprintf(stderr, "Invalid height: %d\n", height);
					exit(1);
				}
				break;
			case 'v':
				usage(0);
				exit(0);
				break;
			default:
				fprintf(stderr, "Try `qrencode --help' for more information.\n");
				exit(1);
				break;
		}
	}

	if(argc == 1) {
		usage(1);
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

	writePNG(intext, outfile);

	return 0;
}
