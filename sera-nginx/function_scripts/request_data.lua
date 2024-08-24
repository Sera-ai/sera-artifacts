local ngx = ngx
local cjson = require "cjson.safe"
local resolver = require "resty.dns.resolver"

-- Function to extract headers and target URL
local function extract_headers_and_url(given_url, reg_host)
    local headers = ngx.req.get_headers()
    local target_url

    if given_url then
        target_url = given_url
    end
    
    if not given_url then
        target_url = headers["X-Forwarded-For"]
    end

    if not target_url then
        target_url = reg_host
    end

    -- Append the request URI to the target URL to preserve the resource path
    local uri = ngx.var.uri
    target_url = target_url .. uri

    -- Add cookies to headers if present
    local cookies = ngx.var.http_cookie
    if cookies then
        headers["Cookie"] = cookies
    end

    return headers, target_url
end

-- Function to get request body for applicable methods
local function get_request_body(method)
    if method == "POST" or method == "PUT" or method == "PATCH" then
        ngx.req.read_body()
        return ngx.req.get_body_data()
    end
    return nil
end

-- Function to resolve the hostname
local function resolve_hostname(hostname)
    local r, err = resolver:new{
        nameservers = {"8.8.8.8", "8.8.4.4"},
        retrans = 5,  -- Retries
        timeout = 2000,  -- 2 sec
    }

    if not r then
        ngx.log(ngx.ERR, "Failed to create the resolver: ", err)
        return nil, err
    end

    local answers, err = r:query(hostname, {qtype = r.TYPE_A})
    if not answers then
        ngx.log(ngx.ERR, "Failed to query the DNS server: ", err)
        return nil, err
    end

    if answers.errcode then
        ngx.log(ngx.ERR, "Server returned error code: ", answers.errcode, ": ", answers.errstr)
        return nil, answers.errstr
    end

    for _, ans in ipairs(answers) do
        if ans.address then
            return ans.address, nil
        end
    end

    return nil, "No A record found"
end


local function mergeTables(t1, t2)
    local mergedTable = {}
    -- Copy all key-value pairs from the first table
    for k, v in pairs(t1) do
        if type(v) ~= "function" then
            mergedTable[k] = v
        end
    end
    -- Copy key-value pairs from the second table only if the key does not exist in the first table and the value is not a function
    for k, v in pairs(t2) do
        if mergedTable[k] == nil and type(v) ~= "function" then
            mergedTable[k] = v
        end
    end
    return mergedTable
end

local function update_json_values(original, data, replacements, sera_res)
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(value) == "table" then
                update_json_values(original, value, replacements, sera_res)
            else
                -- ngx.log(ngx.ERR, "Replace Key: ", key)
                -- ngx.log(ngx.ERR, "replacements: ", cjson.encode(replacements))
                -- ngx.log(ngx.ERR, "Replace Key Obj: ", replacements[key])
                -- ngx.log(ngx.ERR, "Replace Origin: ", cjson.encode(original))
                if replacements[key] then
                    local val_res = split(replacements[key], ".")
                    -- ngx.log(ngx.ERR, "val_res: ", cjson.encode(val_res))
                    if val_res[1] then
                        if string.find(val_res[1], "body") then
                            -- ngx.log(ngx.ERR, "value_res: ", val_res[2])
                            -- ngx.log(ngx.ERR, "replacements: ", replacements[val_res[2]])
                            -- ngx.log(ngx.ERR, "original: ", original[val_res[2]])
                            data[key] = original[val_res[2]] or value
                        else
                            data[key] = sera_res[val_res[1]][val_res[2]] or value
                        end
                    end
                else
                    ngx.log(ngx.ERR, "REPLACEMENT NOT FOUND " .. key)
                    -- ngx.log(ngx.ERR, "replacements: ", cjson.encode(replacements))
                end
            end
        end
    end
end

function split(str, delimiter)
    local result = {}
    local from = 1
    ngx.log(ngx.ERR, str)
    -- Escape the delimiter if it's a special character
    local delim_pattern = delimiter:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
    local delim_from, delim_to = string.find(str, delim_pattern, from)
    while delim_from do
        table.insert(result, string.sub(str, from , delim_from-1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim_pattern, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

-- Function to check if the hostname is an IP address
local function is_ip_address(hostname)
    if not hostname then
        return false
    end
    return hostname:match("^%d+%.%d+%.%d+%.%d+$") ~= nil
end

local function is_valid_json(str)
    local success, result = pcall(cjson.decode, str)
    return success
end

local function pretty_json(json_table, indent)
    local result = {}
    local indent = indent or 0
    local padding = string.rep("  ", indent)

    for k, v in pairs(json_table) do
        local key = type(k) == "string" and string.format("%q", k) or k
        if type(v) == "table" then
            table.insert(result, string.format("%s%s: {", padding, key))
            table.insert(result, pretty_json(v, indent + 1))
            table.insert(result, string.format("%s}", padding))
        else
            local value = type(v) == "string" and string.format("%q", v) or tostring(v)
            table.insert(result, string.format("%s%s: %s,", padding, key, value))
        end
    end

    return table.concat(result, "\n")
end

return {
    get_request_body = get_request_body,
    extract_headers_and_url = extract_headers_and_url,
    mergeTables = mergeTables,
    update_json_values = update_json_values,
    resolve_hostname = resolve_hostname,
    is_ip_address = is_ip_address,
    is_valid_json = is_valid_json,
    pretty_json = pretty_json
}