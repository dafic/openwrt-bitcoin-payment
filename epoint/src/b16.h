/* encode n bytes of in, terminate out with '\0'
   return the encoded bytes (without the '\0') or -2 if out is small
   success is guaranteed if nout >= B16LEN(n)+1 */
int b16enc(const unsigned char *in, int n, char *out, int nout);
#define B16LEN(n) (2*(n))
