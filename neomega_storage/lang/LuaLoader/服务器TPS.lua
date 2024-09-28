local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of 服务器TPS:  ",json.encode(coromega.config))

-- 如果你需要调试请将下面一段解除注释，关于调试的方法请参考文档
-- local dbg = require('emmy_core')
-- dbg.tcpConnect('localhost', 9966)
-- print("waiting...")
-- for i=1,1000 do -- 调试器需要一些时间来建立连接并交换所有信息
--     -- 如果始终无法命中断点，你可以尝试将 1000 改的更大
--     print(".")
-- end
-- print("end")

coromega:when_called_by_terminal_menu({
    triggers = { "服务器TPS", "TPS", "tps" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "获取服务器的TPS",
}):start_new(function(input)
    print("hello from 服务器TPS!")
end)

coromega:when_called_by_game_menu({
    triggers = { "服务器TPS", "TPS", "tps" },
    argument_hint = "",
    usage = "获取服务器的TPS",
})
:start_new(function(chat)
    local caller_name = chat.name
    local player = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    local tps = math.floor(2000 * coromega:sync_ratio()) / 100
    player:say("服务器TPS: " .. tostring(tps) .. "/20")
end)

coromega:when_receive_filtered_cqhttp_message_from_default():start_new(function(source, name, message)
    if message == "TPS" then
        local tps = math.floor (2000 * coromega:sync_ratio()) / 100
        local tq = "服务器TPS: " .. tostring(tps) .. "/20"
        coromega:send_cqhttp_message(source, tq)
    end
end)


coromega:run()
