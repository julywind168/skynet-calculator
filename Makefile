include platform.mk

LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC) -I$(LUALIB_INC) $(MYCFLAGS)

LUA_STATICLIB := skynet/3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= skynet/3rd/lua
LUALIB_INC ?= ./lualib-src

$(LUA_STATICLIB) :
	cd 3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)


LUA_CLIB = storage \


all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 


$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)


$(LUA_CLIB_PATH)/storage.so : lualib-src/lua-util.c lualib-src/lua-storage.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@


clean :
	rm -f $(LUA_CLIB_PATH)/*.so && \
  	rm -rf $(LUA_CLIB_PATH)/*.dSYM