/*  hex.h - Hexademical (base16) encoding and decoding.
    
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

#ifndef EPOINT_HEX_H
#define EPOINT_HEX_H

#include <stddef.h>

extern const char *hexdigits;

/**
 Decode hex-encoded data.
 If output buffer is not large enough, function will write as much data 
 as possible.
 @param in Data to decode.
 @param size Input size in bytes.
 @param out Output buffer.
 @param out_size Output buffer size. .
 @return Number of written decoded bytes.
 */
size_t hexdecode(const char *in, size_t size, char *out, size_t out_size);

/**
 Hex-encode data.
 If output buffer is not large enough, function will write as much data 
 as possible. When possible, output will be null-terminated.
 @param in Data to encode.
 @param size Input size in bytes.
 @param out Output buffer.
 @param out_size Output buffer size. 
 @return Number of written encoded bytes.
 */
size_t hexencode(const char *in, size_t size, char *out, size_t out_size);

#endif /* EPOINT_HEX_H */
