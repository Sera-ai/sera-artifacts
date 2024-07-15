-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local ngx = ngx

local function extract_value(source, key)
    local keys = {}
    for part in key:gmatch("[^.]+") do
        table.insert(keys, part:lower()) -- convert key parts to lowercase
    end
    
    local value = source
    for _, k in ipairs(keys) do
        if type(value) == "table" then
            local lower_keys = {}
            for orig_key in pairs(value) do
                lower_keys[orig_key:lower()] = orig_key
            end
            k = lower_keys[k] -- get the original key case from the table
            value = value and value[k]
        else
            value = nil
            break
        end
    end
    return value
end

local function send_event(response_data, node_data, event_name)
    local evt_httpc = http.new()
    evt_httpc:set_timeout(10000) -- Set a very short timeout

    ngx.log(ngx.ERR, "send_event working")
    local headers = response_data.headers or {}
    local body = cjson.decode(response_data.body) or {}
    local status = response_data.status or 0

    ngx.log(ngx.ERR, cjson.encode(body.origin))

    local event_data = {}

    for _, node in ipairs(node_data) do
        local source, key = node:match("^(.-)%.(.+)$")
        if source and key then
            local source_lower = source:lower()
            if source_lower == "headers" then
                event_data[source] = event_data[source] or {}
                event_data[source][key] = extract_value(headers, key)
            elseif source_lower:match("^body %((%d+)%)$") then
                local expected_status = tonumber(source_lower:match("%((%d+)%)"))

                
                if type(status) ~= "number" then
                    status = tonumber(status)
                end      
                          
                if status == expected_status then
                    event_data["body (" .. status .. ")"] = event_data["body (" .. status .. ")"] or {}
                    event_data["body (" .. status .. ")"][key] = extract_value(body, key)
                end
            elseif source_lower == "body" then
                event_data["body"] = event_data["body"] or {}
                event_data["body"][key] = extract_value(body, key)
            end
        end
    end

    -- Do something with event_data and event_name, e.g., log or send it somewhere
    ngx.log(ngx.ERR, "Event Name: ", event_name, " | Event Data: ", cjson.encode(event_data))

    local send_body = {
        event_name = event_name, 
        data = event_data
    }

    -- Perform the request with a short timeout
    local evt_res, evt_err = evt_httpc:request_uri("http://127.0.0.1:12030/manage/events", {
        method = "POST",
        headers = {
            ['Content-Type'] = 'application/json',
            ['x-sera-service'] = "be_builder"
        },
        body = cjson.encode(send_body),
        ssl_verify = false -- Add proper certificate verification as needed
    })

    -- Since we set a short timeout, we don't care about the response
    if not evt_res then
        ngx.log(ngx.ERR, 'Error creating event: ', evt_err)
    end
end

return {
    send_event = send_event
}
