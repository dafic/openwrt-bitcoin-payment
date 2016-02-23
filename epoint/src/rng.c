/*  rng.c - Random number generator.
    
    Copyright (C) 2009 ePoint Systems Ltd.
    Author: Rooslan S. Khayrov
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <string.h>
#include <time.h>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <fcntl.h>

#include <gcrypt.h>

#include "rng.h"

static char *serial_file = "/tmp/epoint.serial";

/**
 Extract router WAN IP address from "/var/state/network" file.
 @param buf Buffer to recieve IP address in dot-decimal notation.
 @param bufsize Buffer size.
 @return Length of IP address string, not including final NUL.
 */
int wan_ipaddr(char *buf, size_t bufsize)
{
    char linebuf[1024];
    static const char key[] = "network.wan.ipaddr";
    static const size_t keysize = sizeof(key) - 1;
    FILE *state = fopen("/var/state/network", "r");
    if (!state)
    {
        return -1;
    }
    while (fgets(linebuf, sizeof(linebuf), state))
    {
        if (!strncmp(linebuf, key, keysize))
        {
            char *ipaddr = linebuf + keysize + strspn(linebuf + keysize, "= \t");
            ipaddr[strspn(ipaddr, "0123456789.")] = 0;
            strncpy(buf, ipaddr, bufsize);
            if (bufsize > 0)
            {
                buf[bufsize - 1] = 0;
            }
            fclose(state);
            return strlen(ipaddr);
        }
    }
    fclose(state);
    return -1;
}

int gen_random(char *buf, const char *seed, size_t seed_size)
{
    gcry_md_hd_t md;
    unsigned char *digest;
    if (gcry_md_open(&md, GCRY_MD_SHA1, 0))
    {
        return 1;
    }
    gcry_md_write(md, seed, seed_size);
    {
        char ipaddr[16];
        wan_ipaddr(ipaddr, sizeof(ipaddr));
        /* there can be garbage at the end of ipaddr, but it doesn't matter */
        gcry_md_write(md, ipaddr, sizeof(ipaddr));
    }
    {
        time_t t = time(NULL);
        gcry_md_write(md, &t, sizeof(t));
    }
    {
        pid_t pid = getpid();
        gcry_md_write(md, &pid, sizeof(pid));
    }
    {
        int urandom_fd = open("/dev/urandom", O_RDONLY);
        if (urandom_fd >= 0)
        {
            char fbuf[4];
            read(urandom_fd, fbuf, sizeof(fbuf));
            close(urandom_fd);
            gcry_md_write(md, fbuf, sizeof(fbuf));
        }
    }
    {
        int serial_fd = open(serial_file, O_RDWR | O_CREAT, 0644);
        if (serial_fd >= 0)
        {
            unsigned long serial;
            flock(serial_fd, LOCK_EX);
            ssize_t bread = read(serial_fd, &serial, sizeof(serial));
            if (bread < sizeof(serial))
            {
                serial = 0;
            }
            ++serial;
            lseek(serial_fd, 0, SEEK_SET);
            write(serial_fd, &serial, sizeof(serial));
            ftruncate(serial_fd, sizeof(serial));
            close(serial_fd);
            gcry_md_write(md, &serial, sizeof(serial));
        }
    }
    gcry_md_final(md);
    digest = gcry_md_read(md, 0);
    if (!digest)
    {
        gcry_md_close(md);
        return 1;
    }
    memcpy(buf, digest, RAND_SIZE);
    gcry_md_close(md);
    return 0;
}
