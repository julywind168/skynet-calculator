#define LUA_LIB

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "lua-util.h"

static lua_State *sL = NULL;
static void *sT = NULL;

static int
linit(lua_State *L)
{
    if (sL)
    {
        return luaL_error(L, "Already initialized");
    }
    sL = luaL_newstate();
    lua_gc(sL, LUA_GCSTOP, 0);
    xcopy_t(L, sL, 1);
    sT = (void *)lua_topointer(sL, 1);
    return 1;
}

static int
lquery(lua_State *L)
{
    if (sT == NULL)
    {
        return luaL_error(L, "Uninitialized");
    }
    lua_clonetable2(L, sT);
    return 1;
}

LUAMOD_API int
luaopen_storage(lua_State *L)
{
    luaL_checkversion(L);
    luaL_Reg l[] = {
        {"init", linit},
        {"query", lquery},
        {NULL, NULL},
    };
    luaL_newlib(L, l);
    return 1;
}