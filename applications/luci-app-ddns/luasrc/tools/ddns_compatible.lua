#!/usr/bin/lua
-- Copyright (C) 2021 Lienol <lawlienol@gmail.com>

local jsonc = require "luci.jsonc"

local gen_path = "/etc/ddns"
local gen4_path = gen_path .. "/services"
local gen6_path = gen_path .. "/services_ipv6"
local ddns_path = "/usr/share/ddns/default"
local file, err = io.open(ddns_path, "rb")
if file then
    file:close()
    os.execute("mkdir -p " .. gen_path)
    local s = io.popen("ls " .. ddns_path)
    local files_name = s:read("*all")
    string.gsub(files_name, '[^' .. "\n" .. ']+', function(name)
        file = io.open(ddns_path .. "/" .. name, "r")
        local t = jsonc.parse(file:read("*a"))
        if t and t.name then
            if t.ipv4 and t.ipv4.url then
                --local str = string.format('\"%s\" \"%s\"', t.name, t.ipv4.url)
                os.execute(string.format("sed -i '/%s/d' %s >/dev/null 2>&1", t.name, gen4_path))
                os.execute("printf \"%s\\t%s\\n\" '\"" .. t.name .. "\"' " .. "'\"" .. t.ipv4.url .. "\"'" .. ">>" .. gen4_path)
            end
            if t.ipv6 and t.ipv6.url then
                --local str = string.format('"%s" "%s"', t.name, t.ipv6.url)
                os.execute(string.format("sed -i '/%s/d' %s >/dev/null 2>&1", t.name, gen6_path))
                os.execute("printf \"%s\\t%s\\n\" '\"" .. t.name .. "\"' " .. "'\"" .. t.ipv6.url .. "\"'" .. ">>" .. gen6_path)
            end
        end
        file:close()
    end)
end
