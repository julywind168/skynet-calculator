#include <stdio.h>
#include <lua.h>
#include "lua-util.h"

void xcopy(lua_State *F, lua_State *T, int n)
{
    double num;
    switch (lua_type(F, n))
    {
    case LUA_TNIL:
        lua_pushnil(T);
        break;
    case LUA_TBOOLEAN:
        lua_pushboolean(T, lua_toboolean(F, n));
        break;
    case LUA_TNUMBER:
        num = lua_tonumber(F, n);
        if (num == (int)num)
            lua_pushinteger(T, num);
        else
            lua_pushnumber(T, num);
        break;
    case LUA_TSTRING:
        lua_pushstring(T, lua_tostring(F, n));
        break;
    case LUA_TLIGHTUSERDATA:
        lua_pushlightuserdata(T, (void *)lua_touserdata(F, n));
        break;
    case LUA_TTABLE:
        xcopy_t(F, T, n);
        break;
    default:
        fprintf(stderr, "xcopy error: unsupported data type %s\n", lua_typename(F, lua_type(F, n)));
        break;
    }
}

void xcopy_t(lua_State *F, lua_State *T, int n)
{
    int w;
    lua_newtable(T);
    w = lua_gettop(T);
    lua_pushnil(F); /* first key */

    while (lua_next(F, n) != 0)
    {
        xcopy(F, T, -2);
        if (lua_type(F, -1) == LUA_TTABLE)
            xcopy_t(F, T, lua_gettop(F));
        else
            xcopy(F, T, -1);
        lua_settable(T, w);
        lua_pop(F, 1);
    }
}
