local skynet = require "skynet"

local store = require "storage".query()
local game = require "game".game


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, params)
		local f = game[cmd]
		if f then
			skynet.ret(skynet.pack(f(params, store)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)
