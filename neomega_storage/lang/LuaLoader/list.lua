local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of list:  ",json.encode(coromega.config))

-- 如果你需要调试请将下面一段解除注释，关于调试的方法请参考文档
-- local dbg = require('emmy_core')
-- dbg.tcpConnect('localhost', 9966)
-- print("waiting...")
-- for i=1,1000 do -- 调试器需要一些时间来建立连接并交换所有信息
--     -- 如果始终无法命中断点，你可以尝试将 1000 改的更大
--     print(".")
-- end
-- print("end")

coromega:when_receive_filtered_cqhttp_message_from_default():start_new(function(source, name, message)
    if message == "list" then
        local tps = math.floor(tostring(coromega:sync_ratio() * 2000)) / 100
        local players = coromega:get_all_online_players()
        local players_name = {}
        for i, v in ipairs(players) do
            local player_name = v:name()
            players_name[#players_name + 1] = tostring(i) .. ". " .. player_name
        end
        local players_list = table.concat(players_name, "\n")
        local players_length = #players
        local bot_name = coromega:bot_name()
        local msg = ("当前 %s 人在线: \n%s\n机器人: %s\n服务器TPS: %s / 20"):format(players_length, players_list, bot_name, tps)
        coromega:send_cqhttp_message(source, msg)
    end
end)


coromega:run()
