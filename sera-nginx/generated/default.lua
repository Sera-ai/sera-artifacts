-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local learning_mode = require "learning_mode"
local request_data = require "request_data"
local mongo_handler = require "mongo_handler"
local ngx = ngx

-- Connection pool settings
local httpc = http.new()
httpc:set_keepalive(60000, 100) -- keep connections alive for 60 seconds, max 100 connections

-- Function to handle the response
local function handle_response(res, host)

    ngx.log(ngx.ERR, "Response made")
    if not res then
        ngx.log(ngx.ERR, 'Error making request')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if res.status >= 400 then
        ngx.log(ngx.ERR, 'Request failed with status: ', res.status)
        ngx.status = res.status
        ngx.say(res.body)
        ngx.thread.spawn(learning_mode.log_request, res, host)
        return ngx.exit(res.status)
    end

    -- Set response headers
    for k, v in pairs(res.headers) do
        ngx.header[k] = v
    end

    -- Return the response body
    ngx.status = res.status
    ngx.say(res.body)
    ngx.eof()

    -- Spawn a worker thread to handle logging asynchronously
    ngx.thread.spawn(learning_mode.log_request, res, host)
end



-- Function to perform the request
local function make_request()
    ngx.var.proxy_script_start_time = ngx.now()

    local db_entry_host = nil
    ngx.log(ngx.ERR, ngx.var.host)

    local headers = ngx.req.get_headers()

    for key, value in pairs(headers) do
        if type(value) == "table" then
            value = table.concat(value, ", ")
        end
        ngx.log(ngx.ERR, key .. ": " .. value)
    end

    local x_forwarded_for = ngx.req.get_headers()["X-Forwarded-For"]
    local hostname

    if x_forwarded_for and (ngx.var.host == "localhost" or ngx.var.host == "127.0.0.1") then
        hostname = x_forwarded_for
    else
        hostname = ngx.var.host
    end

    ngx.log(ngx.ERR, ngx.var.host)
    ngx.log(ngx.ERR, x_forwarded_for)
    ngx.log(ngx.ERR, hostname)

        
    local query = { hostname = hostname }
    local sera_hosts_json, err = mongo_handler.get_settings("sera_hosts", query)

    if err then
        ngx.log(ngx.ERR, err)
    end

    local protocol = ngx.var.scheme

    if sera_hosts_json then
        local sera_hosts = cjson.decode(sera_hosts_json)
        if sera_hosts then
            protocol = sera_hosts.sera_config.https and "https" or "http"
            local db_entry_port = ((protocol == "http" and sera_hosts.frwd_config.port ~= 80) or 
                (protocol == "https" and sera_hosts.frwd_config.port ~= 443)) 
                and ":" .. sera_hosts.frwd_config.port or ""
            db_entry_host = protocol .. "://" .. sera_hosts.frwd_config.host .. db_entry_port
        end
    end

    if not db_entry_host then
        ngx.log(ngx.ERR, 'No sera_hosts entry found for host: ', hostname)
    end

    ngx.var.proxy_start_time = ngx.now()
    
    local headers, target_url = request_data.extract_headers_and_url(db_entry_host, protocol .. "://" .. hostname)
    headers["Host"] = hostname

    local method = ngx.var.request_method
    local body = request_data.get_request_body(method)
    local query_params = ngx.req.get_uri_args()

    ngx.log(ngx.ERR, "Making request to: " .. target_url)

    -- Make the HTTP request using the resolved IP
    local res, err = httpc:request_uri(target_url, {
        method = method,
        headers = headers,
        body = body,
        query = query_params,
        ssl_verify = false
    })

    ngx.var.proxy_finish_time = ngx.now()

    handle_response(res, hostname)
end

return {
    make_request = make_request
}
