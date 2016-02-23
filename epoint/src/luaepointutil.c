/*  Miscellaneous utility functions for Lua.
    
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
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/file.h>

#include "b64.h"

/* prototypes for ansi c compliance */
int fileno(FILE *);
int setenv(const char *, const char *, int);

static int lua_flock(lua_State *L)
{
    FILE **f;
    const char *mode;
    int fd = -1, op;
    
    f = (FILE**)luaL_checkudata(L, 1, "FILE*");
    if (!f)
    {
        return luaL_argerror(L, 1, "file handle required");
    }
    if (*f)
    {
        fd = fileno(*f);
    }
    if (fd < 0)
    {
        return luaL_argerror(L, 1, "invalid file handle");
    }
    mode = lua_tostring(L, 2);
    if (!mode)
    {
        return luaL_argerror(L, 2, "mode string required: 's', 'x' or 'u'");
    }
    if (!strcmp(mode, "s"))
    {
        op = LOCK_SH;
    }
    else if (!strcmp(mode, "x"))
    {
        op = LOCK_EX;
    }
    else if (!strcmp(mode, "u"))
    {
        op = LOCK_UN;
    }
    else
    {
        return luaL_argerror(L, 2, "invalid lock mode: must be 's', 'x' or 'u'");
    }
    
    if (flock(fd, op))
    {
        lua_pushstring(L, strerror(errno));
        return lua_error(L);
    }
    
    lua_pushboolean(L, 1);
    return 1;
}

static int lua_rename(lua_State *L)
{
    const char *oldpath, *newpath;
    
    oldpath = lua_tostring(L, 1);
    newpath = lua_tostring(L, 2);
    if (!oldpath || !newpath)
    {
        lua_pushstring(L, "two string arguments required: oldpath and newpath");
        return lua_error(L);
    }
    if (rename(oldpath, newpath))
    {
        lua_pushstring(L, strerror(errno));
        return lua_error(L);
    }
    
    lua_pushnil(L);
    return 1;
}

static int lua_setenv(lua_State *L)
{
    const char *varname, *value;
    
    varname = lua_tostring(L, 1);
    value = lua_tostring(L, 2);
    if (!varname || !value)
    {
        lua_pushstring(L, "two string arguments required: variable name and value");
        return lua_error(L);
    }

    if (setenv(varname, value, 1))
    {
        lua_pushstring(L, strerror(errno));
        return lua_error(L);
    }

    lua_pushnil(L);
    return 1;
}

static int lua_b64decode(lua_State *L)
{
    size_t datalen;
    size_t declen;
    const char *data = lua_tolstring(L, 1, &datalen);
    void *decoded;

    if (!data)
        return luaL_argerror(L, 1, "string argument required");
    declen = 3 * (datalen/4) + 2;
    decoded = malloc(declen);
    if (!decoded || (declen = b64dec(data, datalen, decoded, declen)) < 0) {
        lua_pushstring(L, "invalid base64 sequence");
        return lua_error(L);
    }
    lua_pushlstring(L, decoded, declen);
    free(decoded);
    return 1;
}

static int lua_toint(lua_State *L)
{
    lua_Integer n = lua_tointeger(L, 1);
    lua_pushinteger(L, n);
    return 1;
}

static const luaL_Reg exports[] = {
    { "flock", lua_flock },
    { "rename", lua_rename },
    { "setenv", lua_setenv },
    { "b64decode", lua_b64decode },
    { "toint", lua_toint },
    { NULL, NULL } };

LUALIB_API int luaopen_epoint_util(lua_State *L)
{
    luaL_register(L, "epoint.util", exports);
    return 0;
}
