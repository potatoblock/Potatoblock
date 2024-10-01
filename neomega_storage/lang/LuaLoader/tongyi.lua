local omega = require("omega")
local json = require("json")
package.path = ("%s;%s"):format(
    package.path,
    omega.storage_path.get_code_path("LuaLoader", "?.lua")
)
local coromega = require("coromega").from(omega)
local ApiKey,Model = coromega.config["密钥"],coromega.config["模型"]
local keyword=coromega.config["群内触发词"]

local function tongyi(content)
    local url = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

    local payload = {
        model = Model,
        input = {
            messages = {
                {
                    role = "system",
                    content = "You are a helpful assistant."
                },
                {
                    role = "user",
                    content = content
                }
            }
        },
        parameters = {
            enable_search=true -- 是否开启联网搜索
        }
    }
    local headers = {
        ["Authorization"] = "Bearer "..ApiKey,
        ["Content-Type"] = "application/json"

    }
    local response, error_message = coromega:http_request("post", url,{headers=headers, body=json.encode(payload)})
    if error_message then
        print("request error: ", error_message)
        return nil
    else
        print("request response body: ", response.body)
        local result=json.decode(response.body)
        return result["output"]["text"]
    end
end

coromega:when_called_by_game_menu({         --游戏
    triggers = { "ai" , "AI" , "人工智能" , "大模型" },
    argument_hint = "",
    usage = "询问通义千问AI一个问题.",
}):start_new(function(chat)
    local player = chat.name
    local caller = coromega:get_player_by_name(player)
    local content = table.concat(chat.msg," ")
    coromega:send_ws_cmd(("execute as %s run tellraw @s \{\"rawtext\":\[\{\"text\":\"§6您的现金余额: \"\},\{\"score\":\{\"objective\":\"cash\",\"name\":\"@s\"\}\}\]\}"):format(player), false)
    local agree = caller:ask("§6使用API进行模型请求会产生费用.这个费用需由您来承担.\n本次请求将会扣除您的现金余额:2分(0.02元),是否继续?\n请输入:\"是\"\/\"否\"\n§c备注: 请确保你有足够多的现金余额.")
    if agree == "是" then
        local cmd_res = coromega:send_ws_cmd(("scoreboard players remove @a\[name=%s,scores=\{cash=2..\}\] cash 2"):format(player), true, 15)
        if cmd_res then
            local success_count = cmd_res.SuccessCount
        if success_count == 0 then
            caller:say("§c余额不足.\n§a请在聊天栏输入\"§6token§a\"进行充值.\n您可以在雪球菜单查看您的现金余额.")
        else
            caller:say("§a已扣款.\n您可以在雪球菜单查看您的现金余额.")
            if content == "" then
                content = caller:ask("请输入你的问题.")
            end
            caller:say("§a请求已发送至通义大模型,等待回复.")
            caller:say("§a当前使用的模型: §6" .. Model)
            local res = tongyi(content)
            if res == nil then
                coromega:send_ws_cmd(("scoreboard players add @a\[name=%s,scores=\{cash=2..\}\] cash 2"):format(player), false)
                caller:say("§c抱歉,模型请求发生了错误.已进行退款.")
            else
                caller:say("\[通义大模型\] " .. res)
            end
        end
        else
            caller:say("Deducting command result getting timeout!")
        end
    else
        caller:say("已取消.")
    end
end)

coromega:when_receive_filtered_cqhttp_message_from_default():start_new(function(source,name,message)    --QQ
    print(("cqhttp 默认监听对象>来源：%s, 消息：%s, 名字：%s"):format(source,message,name))
    print(source,message,name)
    local keyword_length = #keyword
    local message_length = #message
if message:sub(1, keyword_length) == keyword then
    message = message:sub(keyword_length + 1, message_length)
    local content = message
--    local res = tongyi(content)
    local res = "本插件对QQ暂停服务.\n服务器内的服务依旧正常,但是收费."
    if res == nil then
        local tq = "\[通义大模型\] Error!"
        print(tq)
        coromega:send_cqhttp_message_to_default(tq)
    else
        local tq = "\[通义大模型\] " .. res
        print(tq)
        coromega:send_cqhttp_message(source, tq)
    end
end
    
end)

--这个插件捏,其实捏,不是我写的捏()
--我只是二次开发,做了个游戏内收费系统.
--来源是https://community.neomega.top/d/43
--有兴趣可以支持下原作者.

coromega:run()
