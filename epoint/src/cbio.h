/* io with callbacks */

/* io from FILE* */
int getc_stream(void *rd);
int putc_stream(int c, void *wd);

typedef struct {
	unsigned char *p;
	unsigned char *e;
} buffer_t;

/* io from buffer_t */
int getc_buffer(void *rd);
int putc_buffer(int c, void *wd);

/* gets, puts with callbacks */
char *cbgets(char *s, int n, int (*getc)(void *), void *rd);
int cbputs(char *s, int (*putc)(int, void *), void *wd);
