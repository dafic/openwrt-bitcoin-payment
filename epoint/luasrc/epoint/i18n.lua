--[[
    ePoint i18n framework for Lua
    
    Copyright (C) 2010 ePoint Systems Ltd
    Author: Rooslan S. Khayrov
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--


module("epoint.i18n", package.seeall)

local L = require("lpeg")
local protocol = require("luci.http.protocol")
require("luci.fs")
require("uci")

local locale_dir = "/usr/lib/lua/epoint/i18n/"

local language_codes

function lang_available()
    if not language_codes then
        language_codes = {}
        for i, f in ipairs(luci.fs.dir(locale_dir)) do
            local basename, ext = f:match("^([%w%-_]+).lua$")
            if basename and luci.fs.isfile(locale_dir .. f) then
                table.insert(language_codes, basename)
            end
        end
    end
    return language_codes
end

local function match_language_tag(tag)
    local tag = tag:lower()
    local primtag, subtag = tag:match("^(%a+)-(%a+)")
    if not primtag then
        primtag = tag
    end
    local result
    for i, lang in ipairs(lang_available()) do
        local normlang = lang:lower():gsub("_", "-")
        -- full match, return immediately
        if tag == normlang then
            return lang
        end
        -- can be overriden by full match later
        if primtag == normlang then
            result = lang
        end
    end
    return result
end

local function parse_accept_language(header)
    local ident = L.R("AZ", "az") * L.R("AZ", "az") ^ 0
    local lang = L.C(ident * (L.P("-") * ident) ^ 0) + L.P("*")
    local ws = lpeg.S(" \t") ^ 0
    local qval = L.C(
        (L.P("0") * (L.P(".") * L.R("09") ^ -3) ^ -1) +
        (L.P("1") * (L.P(".") * L.P("0") ^ -3) ^ -1)) / tonumber
    local group = L.Ct(
        lang * (ws * L.P(";") * ws * L.P("q") * ws * L.P("=") * ws * qval) ^ -1) /
        function(t)
            if not t[2] then
                return { lang = t[1], qval = 1.0 }
            else
                return { lang = t[1], qval = t[2] }
            end
        end
    local accept_lang = L.Ct(group * (L.P(",") * ws * group) ^ 0)
    local t = accept_lang:match(header)
    -- reverse sort
    table.sort(t, function(x, y) return x.qval > y.qval end)
    return t
end

local function select_accepted_language(header)
    if not header or #header == 0 then
        return nil
    end
    local t = parse_accept_language(header)
    for i, x in ipairs(t) do
        local lang = match_language_tag(x.lang)
        if lang then
            return lang
        end
    end
end

local current_language

function set_language(lang)
    current_language = lang
end

function get_current_language()
    return current_language
end

function translate(msgid, ...)
    require("epoint.i18n." .. get_current_language())
    local translatef = epoint.i18n[get_current_language()].translate
    return translatef(msgid, ...)
end

local param_lang

function cgi_select_language()
    local params = protocol.urldecode_params(os.getenv("QUERY_STRING") or "")
    param_lang = params["lang"] -- cached global variable
    local cookies = os.getenv("HTTP_COOKIE") or ""
    local cookie_lang = cookies:match("lang=([%a%-_]+)")
    local browser_lang = select_accepted_language(os.getenv("HTTP_ACCEPT_LANGUAGE") or "")
    
    local admin_lang = uci.get("luci.main.lang")
    if not admin_lang or admin_lang == "auto" then
        admin_lang = "en"
    end
    local default_lang = uci.get("epoint.config.interface_lang") or admin_lang
    local lang = param_lang or cookie_lang or browser_lang or default_lang
    lang = match_language_tag(lang)
    if not lang then
        lang = default_lang
    end

    set_language(lang)
end

function cgi_set_language_cookie()
    if param_lang then
        io.write(string.format("Set-Cookie: lang=%s\r\n", param_lang))
    end
end
