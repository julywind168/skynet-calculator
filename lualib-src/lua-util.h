#ifndef LUA_UTIL_H
#define LUA_UTIL_H

#include <stdio.h>
#include <lua.h>

void xcopy(lua_State *F, lua_State *T, int n);

void xcopy_t(lua_State *F, lua_State *T, int n);

#endif