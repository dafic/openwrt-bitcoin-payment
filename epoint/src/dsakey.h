typedef struct {
	gcry_mpi_t p;
	gcry_mpi_t q;
	gcry_mpi_t g;
	gcry_mpi_t y;
	gcry_mpi_t x;
} dsakey_t;

void init_gcry(void);

dsakey_t *randtokey(char *rand);
dsakey_t *packettokey(unsigned char *buf, int n);
void freekey(dsakey_t *k);
void dumpkey(dsakey_t *k, FILE *f);

int pubkeypacket(unsigned char *buf, int n, dsakey_t *k);
int seckeypacket(unsigned char *buf, int n, dsakey_t *k);
void fingerprint(unsigned char *md, dsakey_t *k);
