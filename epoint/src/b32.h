/* encode n bytes of in, terminate out with '\0', '=' padding is not added
   return the encoded bytes (without the '\0') or -2 if out is small
   success is guaranteed if nout >= B32LEN(n)+1 */
int b32enc(const unsigned char *in, int n, char *out, int nout);
#define B32LEN(n) ((8*(n)+4)/5)
