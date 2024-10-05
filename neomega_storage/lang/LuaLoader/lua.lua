local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of lua:  ",json.encode(coromega.config))


coromega:when_called_by_game_menu({
    triggers = { "lua" , "Lua" , "LUA" },
    argument_hint = "[Lua语句]",
    usage = "在外部执行lua代码.",
})
:start_new(function(chat)
    local caller_name = chat.name
    local caller = coromega:get_player_by_name(caller_name)
    local input = chat.msg
    if chat.msg == nil then
        caller:say("您的请求中没有Lua语句. 请重新开启菜单, 并输入Lua语句. \n调用示例: lua return 1 + 1")
        return
    end
    local input = table.concat(input, " ")
    local func = loadstring(input)
    local res = (func())
    local res = res()
    local tm = "Lua Function Result: \n" .. tostring(res)
    caller:say(tm)
end)

coromega:when_receive_filtered_cqhttp_message_from_default():start_new(function(source, name, message)
    local keyword = message:sub(1, 4)
    if keyword == "lua " or keyword == "Lua " or keyword == "LUA " then
        if #message < 5 then
            coromega:send_cqhttp_message(source, "您的请求中没有Lua语句. 请重新开启菜单, 并输入Lua语句. \n调用示例: lua return 1 + 1")
            return
        end
        msg = message:sub(5, #message)
        local func = loadstring(msg)
        local func = func()
        local tq = "Lua Function Result: \n" .. tostring(func)
        coromega:send_cqhttp_message(source, tq)
    end
end)


coromega:run()
