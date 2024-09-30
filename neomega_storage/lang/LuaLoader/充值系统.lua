local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of 充值系统:  ",json.encode(coromega.config))

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
    triggers = { "充值系统" },
    argument_hint = "[arg1] [arg2] ...",
    usage = "对接爱发电的充值系统,用于现金充值.",
}):start_new(function(input)
    print("hello from 充值系统!")
end)

coromega:when_called_by_game_menu({
    triggers = { "充值兑换" , "token" },
    argument_hint = "",
    usage = "对接爱发电的充值系统,用于现金充值.",
})
:start_new(function(chat)
    local caller_name = chat.name
    local caller = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    local mode = caller:ask("请输入你要进行的操作的编号:\n1.购买\n2.兑换")
    if mode == "1" then
        caller:say("§6好的,请用任意软件扫描地上的地图画.\n如果手持地图后不显示,您可以试一试在设置-视频中关闭隐藏手.\n扫描完成并购买后重新启动该菜单,并选择兑换.")
        local QR = coromega.config["充值码结构名"]
        coromega:send_ws_cmd(("execute as %s at @s run structure load %s ~~~"):format(caller_name, QR), false)
    elseif mode == "2" then
        local token = caller:ask("请输入兑换码.\n如果还没有,请重新启动本菜单项,并选择购买选项.")
        local function IsInTable(value, tbl)
            for k, v in ipairs(tbl) do
                if v == "占位" then
                    return {false}
                elseif v == value then
                    tbl[k] = "占位"
                    return {true, tbl}
                end
            end
            return {false}
        end
        local db = coromega:key_value_db("兑换码库", "json")
        db:set("占位", "null")
        local rmb_5 = db:get("RMB5")
        local rmb_10 = db:get("RMB10")
        if rmb_5 == nil then
            db:set("RMB5", {})
            local rmb_5 = {}
        end
        if rmb_10 == nil then
            db:set("RMB10", {})
            local rmb_10 = {}
        end
        local in_table_5 = IsInTable(token, rmb_5)
        local in_table_10 = IsInTable(token, rmb_10)
        if in_table_5[1] == true then
            local rmb_5 = in_table_5[2]
            db:set("RMB5", rmb_5)
            coromega:send_ws_cmd(("scoreboard players add %s cash 500"):format(caller_name), false)
            caller:say("§a兑换成功: 5元.\n余额已到账.")
        elseif in_table_10[1] == true then
            local rmb_10 = in_table_10[2]
            db:set("RMB10", rmb_10)
            coromega:send_ws_cmd(("scoreboard players add %s cash 1000"):format(caller_name), false)
            caller:say("§a兑换成功: 10元.\n余额已到账.")
        else
            caller:say("§c兑换码错误.")
        end
    end
end)


coromega:run()
