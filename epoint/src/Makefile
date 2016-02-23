EXTRA_CFLAGS=-Wall -fpic --std=c99

all: epoint urldecode crypto.so util.so getsockname

%.o: %.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $^

epoint: b64.o hex.o verify.o sign.o dsatool.o main.o b64decode.o dsakey.o cbio.o clear.o armor.o crc24.o
	$(CC) -o $@ $^ -L $(STAGING_DIR)/usr/lib -lgcrypt -lopencdk -lgpg-error -lz

urldecode: urldecode.o
	$(CC) -o $@ $^

crypto.so: luacrypto.o hex.o
	$(CC) -shared -o $@ $^ -L $(STAGING_DIR)/usr/lib -lgcrypt -llua

util.so: luaepointutil.o b64.o
	$(CC) -shared -o $@ $^ -L $(STAGING_DIR)/usr/lib -llua

getsockname: getsockname.o
	$(CC) -o $@ $^

bxxtest: bxxtest.o b16.o b32.o b64.o
	$(CC) -o $@ $^

test: bxxtest
	./bxxtest

clean:
	rm -fv *~ a.out *.o *.so epoint urldecode countercheck getsockname bxxtest
