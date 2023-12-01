#define LUA_LIB

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static lua_State *sL = NULL;
static void *sT = NULL;

void init()
{
    if (sL == NULL)
    {
        sL = luaL_newstate();
        lua_gc(sL, LUA_GCSTOP, 0);
        lua_newtable(sL);
        sT = (void *)lua_topointer(sL, 1);
    }
}

static int
lquery(lua_State *L)
{
    lua_clonetable2(L, sT);
    return 1;
}

LUAMOD_API int
luaopen_storage(lua_State *L)
{
    luaL_checkversion(L);
    luaL_Reg l[] = {
        {"query", lquery},
        {NULL, NULL},
    };
    luaL_newlib(L, l);
    init();
    return 1;
}