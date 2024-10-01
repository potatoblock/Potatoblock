local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of 削藩助手:  ",json.encode(coromega.config))

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
    triggers = { "削藩助手" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "帮助服主撤销不在线的管理员权限。",
}):start_new(function(input)
    print("hello from 削藩助手!")
end)

coromega:when_called_by_game_menu({
    triggers = { "削藩助手" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "帮助服主撤销不在线的管理员权限。",
})
:start_new(function(chat)
    local caller_name = chat.name
    local caller = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    print(input)
    caller:say("hello from 削藩助手!")
end)

coromega:when_player_change():start_new(function(player, action)
    if action == "online" then
        coromega:sleep(30)
        local fakeop = coromega.config["黑名单管理员"]
        local name = player:name()
        if fakeop == name then
            local result = player:is_op()
            if result == true then
                coromega:send_ws_cmd("deop " .. name)
                coromega:send_player_cmd("clear " .. name)
                if name then
                    coromega:send_ws_cmd("gamemode s " .. name)
                end
                player:say("§r§c§l由于违规行为，您的管理员已被服主裁撤。申诉请向§r§epotatoblock@163.com§r§c§l发送邮件。")
                coromega:send_cqhttp_message_to_default("已成功裁撤管理员: " .. name)
            end
        end
    end
end)


coromega:run()
