all: code128b

code128b: pngenc.c code128font.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ -L $(STAGING_DIR)/usr/lib pngenc.c -lpng -lz

clean:
	rm -f *.o *~ a.out code128b
