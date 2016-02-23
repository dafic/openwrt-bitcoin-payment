/*  rng.h - Random number generator.
    
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

#ifndef EPOINT_RNG_H
#define EPOINT_RNG_H

/**
 Size of random seed and ePoint RANDs in bytes.
 It MUST NOT be bigger than 20 (size of SHA1 hash) to prevent memory 
 corruption.
 */
#define RAND_SIZE 9

/**
 Generate 72-bit (RAND_SIZE bytes) random number. It gathers entropy from:
  * seed value, typically secret key
  * router WAN IP address
  * current time since UNIX epoch
  * current PID
  * /dev/urandom
  * serial number file which is guaranteed to contain non-repeating 
    successive values if kept intact between function invocations.
  Note that function doesn't fail even if it can't read from any of these 
  sources.
 @param buf Buffer to receive generated random number. Must point to 
  pre-allocated buffer at least RAND_SIZE bytes length.
 @param seed Seed value.
 @param seed_size Seed value size (in bytes).
 @return Zero on success, nonzero integer in case of error.
 */
int gen_random(char *buf, const char *seed, size_t seed_size);

#endif /* EPOINT_RNG_H */
