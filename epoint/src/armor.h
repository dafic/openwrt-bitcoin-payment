int armor(int (*putc)(int, void *), void *wd, int (*getc)(void *), void *rd, char *heading, char *headers);

/* returns the bytes written into dst without the closing '\0' */
int armor_buffer(char *dst, int ndst, unsigned char *src, int nsrc, char *heading, char *headers);

unsigned crc24init(void);
unsigned crc24update(unsigned crc, unsigned char *data, unsigned len);
unsigned crc24end(unsigned crc);
