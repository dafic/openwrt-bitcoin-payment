all: qrbmp

qrbmp: qrenc.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ -L $(STAGING_DIR)/usr/lib qrenc.c -lqrencode

clean:
	rm -f *.o *~ a.out qrbmp
