/* returns negative value on failure */
int clearsign(int (*putc)(int, void *), void *wd, int (*getc)(void *), void *rd, dsakey_t *k);

int clearsign_stream(FILE *out, FILE *in, dsakey_t *k);

/* returns the bytes written into dst without the closing '\0' */
int clearsign_buffer(char *dst, int ndst, char *src, int nsrc, dsakey_t *k);
