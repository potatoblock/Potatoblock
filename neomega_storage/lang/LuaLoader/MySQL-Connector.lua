local omega = require("omega")
local json = require("json")
--- @type Coromega
local coromega = require("coromega").from(omega)

print("config of MySQL-Connector:  ",json.encode(coromega.config))

local CFG = coromega.config["数据库配置"]

local function connect(query)
    local url = "http://api.potatoblock.asia:8848/mysql"
    local payload = CFG
    payload["query"] = query
    local response, error_message = coromega:http_request("POST", url, {
        body = json.encode(payload)
    })

    if error_message then
        print("Error connecting with MySQL: ", error_message)
        return nil
    else
        return response.body
    end
end

coromega:when_called_by_api_named("/mysql/connect"):start_new(function(args)
    local query = args[1]
    local result = connect(query)
    return result
end)

coromega:run()
