/* decode until '\0', '=' or n bytes (whichever comes first)
   return the decoded bytes or -1 if not base64 or -2 if out is small
   whitespace is skipped, padding at the end is not checked
   out is big enough if nout >= B64DECLEN(n) */
int b64dec(const char *in, int n, unsigned char *out, int nout);
#define B64DECLEN(n) (((n)+3)/4*3)

/* encode n bytes of in, terminate out with '\0'
   return the encoded bytes (without the '\0') or -2 if out is small
   success is guaranteed if nout >= B64LEN(n)+1 */
int b64enc(const unsigned char *in, int n, char *out, int nout);
#define B64LEN(n) (((n)+2)/3*4)
