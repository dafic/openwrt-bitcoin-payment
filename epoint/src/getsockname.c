#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* gets socket name of stdin for http-redirect */

int main(void) {
	struct sockaddr_in addr;
	socklen_t n = sizeof(addr);
	int r;
	char *s;

	r = getsockname(0, (struct sockaddr *) &addr, &n);
	if(r == 0)
		s = inet_ntoa(addr.sin_addr);
	else
		s = "";
	puts(s);
	return 0;
}
