/*  hex.c - Hexademical (base16) encoding and decoding.
    
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

#include "hex.h"

static inline int hexdigit(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'A' && c <= 'F')
        return 10 + c - 'A';
    if (c >= 'a' && c <= 'f')
        return 10 + c - 'a';
    return -1;
}

const char *hexdigits = "0123456789ABCDEF";

size_t hexdecode(const char *in, size_t size, char *out, size_t out_size)
{
    size_t ipos, wpos;
    if (size == 0)
    {
        return 0;
    }
    for (ipos = wpos = 0; ipos + 2 <= size && wpos < out_size; ipos += 2, ++wpos)
    {
        int d1 = hexdigit(in[ipos]), d2 = hexdigit(in[ipos + 1]);
        if (d1 >= 0 && d2 >= 0)
        {
            out[wpos] = ((unsigned)d1 << 4) | (unsigned)d2;
        }
        else
        {
            return wpos;
        }
    }
    return wpos;
}

size_t hexencode(const char *in, size_t size, char *out, size_t out_size)
{
    size_t ipos, wpos;
    for (ipos = wpos = 0; ipos < size && wpos + 2 <= out_size; ++ipos, wpos += 2)
    {
        out[wpos] = hexdigits[(unsigned char)(in[ipos]) >> 4];
        out[wpos + 1] = hexdigits[(unsigned char)(in[ipos]) & 0x0F];
    }
    if (out_size > wpos)
    {
        out[wpos] = 0;
    }
    return wpos;
}
