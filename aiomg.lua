local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)


local ApiKey,Model = coromega.config["密钥"],coromega.config["模型"]

local function tongyi(content,system_msg)
    local system_msg = system_msg or "You are a helpful assistant."
    local url = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

    local payload = {
        model = Model,
        input = {
            messages = {
                {
                    role = "system",
                    content = system_msg
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


print("config of aiomg:  ",json.encode(coromega.config))

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
    triggers = { "aiomg" },
    argument_hint = "",
    usage = "接入大模型的OMG菜单智能版,可以像魔法指令一样翻译人话为OMG指令.",
}):start_new(function(input)
    print(tongyi.tongyi("你好，我是用户，这是一个测试", "你好，我是系统，我没话要说"))
end)

coromega:when_called_by_game_menu({
    triggers = { "aiomg" },
    argument_hint = "",
    usage = "接入大模型的OMG菜单智能版,可以像魔法指令一样翻译人话为OMG指令.",
})
:start_new(function(chat)
    local caller_name = chat.name
    local caller = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    local msg = table.concat(input, " ")
    if msg == "" then
        msg = caller:ask("请输入你要用OMG菜单实现的功能.")
    end
    caller:say("您的输入为: " .. msg)
    caller:say("正在向通义大模型请求结果。当前模型：" .. Model)
    local system_msg = coromega.config["系统提示语"]
    local result = tongyi(msg, system_msg)
    caller:say("来自通义大模型的返回值: " .. result)
    local omg_cmd = "omg " .. result
    caller:say("已拼接为OMG指令: " .. omg_cmd)
    coromega:send_ws_cmd(("execute as %s run tell @a\[tag=omega_bot\] %s"):format(caller_name, omg_cmd), false)
end)


coromega:run()
