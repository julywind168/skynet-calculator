local skynet = require "skynet"


return function(game, lock)
    lock("")(function()
        function game:test1()
            skynet.error("test1")
            return "hello 1"
        end

        function game:test2()
            skynet.error("test2")
            return "hello 2"
        end
    end)
end
