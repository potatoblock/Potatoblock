local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of 信息留存:  ",json.encode(coromega.config))

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
    triggers = { "信息留存" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "询问玩家个人信息",
}):start_new(function(input)
    print("hello from 信息留存!")
    local db = coromega:key_value_db("玩家联系预留", "json")
    db:set("占位占位占位占位占位", "木有")
end)

coromega:when_called_by_game_menu({
    triggers = { "信息留存" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "询问玩家个人信息",
})
:start_new(function(chat)
    local caller_name = chat.name
    local caller = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    print(input)
    caller:say("hello from 信息留存!")
end)

coromega:when_receive_msg_from_command_block_named("#信息留存"):start_new(function(chat)
    local player_name = chat.msg[1]
    local player = coromega:get_player_by_name(player_name)
    local uuid = player:uuid_string()
    local db = coromega:key_value_db("玩家联系预留", "json")
    db:set("占位占位占位占位占位占位占位", nil)
    local agree = player:ask("§a我服需要询问您的一些联系方式,方便日后有事时对您通知.答题完成后,我服将会向您发放一些小奖励.请问您是否同意?\n请输入\"是\"\/\"否\"")
    if agree == "是" then
        local phone = player:ask("您的手机:\n\(没有请填无\)")
        local qq = player:ask("您的企鹅:\n\(没有请填无\)")
        local email = player:ask("您的邮箱:\n\(没有请填无\)")
        local ps = player:ask("其他备注:\n\(没有请填无\)")
        local data = {["name"]=player_name,["phone"]=phone,["qq"]=qq,["email"]=email,["notes"]=ps}
        local truely = player:ask("§a您确认您的输入是无误的吗?\n请输入\"是\"\/\"否\"")
        if truely == "是" then
            local written = db:get(uuid)
            if written then
                player:say("感谢您的支持,但您已经提交过了,所以不爆金币了.")
            else
                player:say("感谢您的支持,已为您爆金币:1000元.\n可在雪球菜单或玩家列表查看您的资产总额.")
                coromega:send_ws_cmd(("scoreboard players add %s money 1000"):format(player_name), false)
            end
            db:set(uuid, data)
            player:say("存储完毕.\n再次提交将会覆盖这次的记录.")
        else
            player:say("好的,已取消存储.如需再次记录，请前往主城.感谢您的参与!")
        end
    else
        player:say("好的,我服将不再询问.如需再次记录,请前往主城.")
    end
end)


coromega:run()
