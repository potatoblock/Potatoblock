local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

coromega:print("config of 获取网易UUID:  ",json.encode(coromega.config))

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
    triggers = { "获取网易UUID" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "在玩家加入游戏时将其网易账号UUID同步到记分板",
}):start_new(function(input)
    coromega:print("hello from 获取冈易UUID!")
end)

coromega:when_called_by_game_menu({
    triggers = { "获取网易UUID" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "在玩家加入游戏时将其网易账号UUID同步到记分板",
})
:start_new(function(chat)
    local caller_name = chat.name
    local caller = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    coromega:print(input)
    caller:say("hello from 获取冈易UUID!")
end)

coromega:when_player_change():start_new(function(player, action)
    if action == "online" then
        local qq = coromega.config["通知发送"]
        local ban = coromega.config["黑名单设备号"]
        local uuid,found = player:uuid_string()
        local name,found = player:name()
        local botname = coromega:bot_name()
        local hex_part = uuid:sub(-8)
        local uuidint = tonumber(hex_part, 16)
        local uuidint = tostring(uuidint)
        coromega:print(("玩家NE识别码：%s"):format(uuidint))
        local a = math.floor(uuidint / 100000)
        local b = uuidint % 100000
        coromega:sleep(1.0)
        coromega:send_ws_cmd(("scoreboard players set %s uuid1 6%s"):format(name, a), false)
        coromega:send_ws_cmd(("scoreboard players set %s uuid2 6%s"):format(name, b), false)
        coromega:sleep(19.0)
        coromega:send_ws_cmd(("execute at %s run tp %s ~~100~"):format(name, botname), false)
        coromega:sleep(1)
        local deviceidstr = player:device_id()
        coromega:print(("玩家设备号：%s"):format(deviceidstr))
--        local result = coromega:send_player_cmd(("tag %s list"):format(name), true, 1.5)
--        if not result then
--            coromega:print("服务器未响应指令，可能是因为指令存在违禁词")
--        else
--            result = json.encode(result)
--            tags = result.CommandOrigin.OutputMessages.Parameters
--            for i, tag in tags do
--                if tag:sub(3, 4) == "DE" then
--                    tag = tag:sub(3, #tag - 2)
--                    coromega:send_ws_cmd(("tag %s remove %s"):fromat(name, tag), false)
--                end
--            end
--        end
        coromega:sleep(0.1)
        deviceidstr = "DE" .. deviceidstr
        coromega:send_ws_cmd(("tag %s remove %s"):format(name, deviceidstr), false)
        player:say(("§r§f您的设备号是§6%s§f，这是您当前MC应用的唯一ID，不受游戏账号等影响。"):format(deviceidstr))
        player:say(("§r§f您的NE识别码是§6%s§f，这是您当前MC中国版账号的唯一ID，不受游戏昵称等影响。"):format(uuidint))
        coromega:send_cqhttp_message(qq, ("玩家名：%s\nNE识别码：%s\n设备号：%s"):format(name, uuidint, deviceidstr))
        local db = coromega:key_value_db("玩家设备号", "json")
        local necode = db:get(deviceidstr)
        if not necode then
            necode = {}
        else
            player:say(("§r§f您有这些账号在此设备登录过，它们的NE识别码是：§6%s§f"):format(table.concat(necode, ", ")))
            coromega:send_cqhttp_message(qq, ("设备号：%s\n设备下所有账号：%s"):format(deviceidstr, table.concat(necode, ", ")))
        end
        function IsInTable(value, tbl)
            for k, v in ipairs(tbl) do
                if v == value then
                    return true
                end
            end
            return false
        end
        local innecode = IsInTable(uuidint, necode)
        if not innecode then
            necode[#necode + 1] = uuidint
            db:set(deviceidstr, necode)
        end
        for i, de in ipairs(ban) do
            if de == deviceidstr then
                coromega:send_ws_cmd(("kick %s §c您的设备在黑名单内。如需申诉请向§epotatoblock@163.com§c发送邮件。"):format(name), false)
                coromega:send_ws_cmd(("tellraw @a {\"rawtext\":[{\"text\":\"%s由于设备被封禁，已被Potatoblock踢出。\"}]}"):format(name))
            end
        end
    end
end)


coromega:run()
