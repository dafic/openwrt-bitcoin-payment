/*  gcrypt-based cryptography module for Lua
    
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

#include <lua.h>
#include <lauxlib.h>
#include <gcrypt.h>

#include "hex.h"

static int lua_hexdigest(lua_State *L)
{
    int algo;
    const char *algoname, *data;
    size_t len, hexdigest_len;
    char hexdigest[128];
    gcry_md_hd_t md;
    
    algoname = lua_tostring(L, 1);
    if (!algoname)
    {
        return luaL_argerror(L, 1, "hash algorithm name required");
    }
    algo = gcry_md_map_name(algoname);
    if (!algo)
    {
        return luaL_argerror(L, 1, "could not find requested algorithm");
    }
    
    data = lua_tolstring(L, 2, &len);
    if (!data)
    {
        return luaL_argerror(L, 2, "string value required");
    }
    
    if (gcry_md_open(&md, algo, 0))
    {
        return luaL_error(L, "failed to initialize hashing context");
    }
    gcry_md_write(md, data, len);
    gcry_md_final(md);
    
    hexdigest_len = hexencode((const char*)gcry_md_read(md, 0),
                              gcry_md_get_algo_dlen(algo),
                              hexdigest, sizeof(hexdigest));
    lua_pushlstring(L, hexdigest, hexdigest_len);
    
    gcry_md_close(md);
    
    return 1;
}

static int init_gcrypt(lua_State *L) {
    if (!gcry_check_version(GCRYPT_VERSION))
        return luaL_error(L, "failed to initialize libgcrypt");
    gcry_control(GCRYCTL_DISABLE_SECMEM,0,0,0,0,0,0,0);
    gcry_control(GCRYCTL_INITIALIZATION_FINISHED);
    return 0;
}

static const luaL_Reg exports[] = {
    { "hexdigest", lua_hexdigest },
    { NULL, NULL } };

LUALIB_API int luaopen_crypto(lua_State *L)
{
    init_gcrypt(L);
    luaL_register(L, "crypto", exports);
    return 0;
}
