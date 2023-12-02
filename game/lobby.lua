local skynet = require "skynet"


return function(game, lock)
    lock("")(function()
        function game:test(s)
            skynet.error(string.format("test action,  %d user is online.", s.usermgr.count))
            return "HELLO CALCULATOR"
        end
    end)
end
