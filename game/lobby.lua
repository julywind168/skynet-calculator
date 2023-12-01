local skynet = require "skynet"


return function(game, lock)
    lock("")(function()
        function game:test(s)
            skynet.error("test, online =", s.usermgr.online)
            return "HELLO CALCULATOR"
        end
    end)
end
