--[[
    ePoint message parsing library
    
    Copyright (C) 2009, 2010 ePoint Systems Ltd
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

module("epoint.protocol", package.seeall)

local L = require("lpeg")
local http = require("socket.http")
require("luci.fs")
require("crypto")
require("epoint.util")
require("uci")

local issuer = uci.get("epoint.config.issuer")
local issuerpk = uci.get("epoint.config.issuer_pk")
local issuerfpr = uci.get("epoint.config.issuerfpr")


function urlencode(s)
	local function esc(c)
		return string.format("%%%02x", string.byte(c))
	end
	return s:gsub("([^a-zA-Z0-9$_%-%.!*'(),])", esc)
end

-- string of 12 random digits (should be enough to avoid collisions)
local function rnd12()
	local z = string.byte("0")
	local f = io.open("/dev/urandom")
	local s = f:read(12)
	f:close()
	return s:gsub(".", function(c)
		return string.char(z + string.byte(c)%10)
	end)
end

function verify_signature(msg, key)
	local tmpfn = "/tmp/"..rnd12()
	local f = io.open(tmpfn, "w")
	f:write(msg)
	f:close()
	key = key or issuerpk
	local r = os.execute("epoint_verify -k "..key.." "..tmpfn)
	os.remove(tmpfn)
	return r == 0
end

local template_cachedir = "/tmp/epoint-templatecache"

local function compile_template(template_text)
    local ident = L.C(L.R("AZ", "az", "__") * L.R("AZ", "az", "09", "__") ^ 0)
    local var = L.P("$") * (L.P("{") * ident * L.P("}") + ident) +
                L.P("{$") * ident * (1 - L.P("}")) ^ 0 * L.P("}")
    local sep = L.C((1 - var) ^ 0)
    local template = L.Ct(sep * (var * sep) ^ 0)

    local delims = {}
    local vars = {}
    for i, token in ipairs(template:match(template_text)) do
        if i % 2 == 0 then
            table.insert(vars, token)
        else
            table.insert(delims, token)
        end
    end

    local matcher = L.P(delims[1])
    for i, varname in ipairs(vars) do
        local delim = L.P(delims[i + 1])
        local var = L.C((1 - delim) ^ 0) /
            function(c)
                return { name = varname, value = c }
            end
        matcher = matcher * var * delim
    end
    matcher = L.Ct(matcher)

    local function parser(message)
        local result = {}
        for i, pair in ipairs(matcher:match(message)) do
            result[pair.name] = pair.value
        end
        return result
    end

    return parser
end

local function strip_signature(text)
    local start = text:find("\n\n")
    local fini = text:find("\n-----BEGIN PGP SIGNATURE-----", 1, true)
    if start and fini then
        result = text:sub(start + 2, fini):gsub("\n%- ", "\n")
        return result
    else
        return text
    end
end

local function parse_headers(message)
    local header = L.Ct(L.C((L.R("\033\126") - L.S(":")) ^ 1) * L.P(":") *
                        L.S(" \t") ^ 0 * L.C((1 - L.S("\n")) ^ 1) * L.P("\n"))
    local parser = L.Ct(header ^ 0) * L.P("\n") * L.C(L.P(1) ^ 0)
    
    local headers, body = parser:match(message)
    local fields = {}
    for i, pair in ipairs(headers or {}) do
        fields[pair[1]:lower()] = pair[2]
    end
    return fields, body
end

local function fetch_template(url)
    local digest = url:match("/template%?ID=([0-9A-Fa-f]+)$")
    if not digest then
        return nil
    end
    digest = digest:upper()
    local template
    local cache_file = template_cachedir .. "/" .. digest
    if luci.fs.access(cache_file) then
        template = luci.fs.readfile(cache_file)
        local calc_digest = crypto.hexdigest("sha1", template)
        if calc_digest ~= digest then
            template = nil
            luci.fs.unlink(cache_file)
        end
    end
    if not template then
        local body, code = http.request(url)
        if code ~= 200 then
            return nil
        end
        local calc_digest = crypto.hexdigest("sha1", body)
        if calc_digest ~= digest then
            return nil
        end
        template = body
        if not luci.fs.access(template_cachedir) then
            luci.fs.mkdir(template_cachedir)
        end
        luci.fs.writefile(cache_file, template)
    end
    return compile_template(template)
end

--- Parse ePoint message, fetching template if necessary.
-- @param message message text
-- @return table with variable values or nil if message is not valid
function parse_message(message)
    if not verify_signature(message) then
        return nil
    end
    local headers, body = parse_headers(strip_signature(message))
    if headers["content-type"] and headers["document-template"] then
        local parser = fetch_template(headers["document-template"])
        if parser then
            return parser(body)
        end
    end
end

--- Caclulate messge digest of the given rand
function get_md(rand)
    return crypto.hexdigest("sha1", epoint.util.b64decode(rand))
end

--- Verify given message digest.
-- @return table with certificate of value if md is valid, table
--  with negative 'value' field if md does not exists and nil if
--  there were other errors
function verify(md)
    local body, code = http.request(string.format("%s/info?ID=%s",
        issuer, md))
    if code == 200 then
        local cert = parse_message(body)
        if cert then
            cert.value = tonumber(cert.VALUE)
        end
        return cert
    elseif code == 404 then
        -- TODO: value = 0
        return { value = -1 }
    end
end

--- Verify given RAND.
-- @param rand Base64-encoded RAND
-- @return table with certificate of value if RAND is valid, table
--  with negative 'value' field if RAND does not exists and nil if
--  there were other errors
function verify_rand(rand)
    return verify(get_md(rand))
end

--- Obligation transfer

-- cache
local obligation_transfer_template = nil

local function template_by_id(id)
	local body, code = http.request(issuer .. "/template?ID=" .. id)
	if code ~= 200 then
		return nil
	end
	return body
end

local function datestr(t)
	return os.date("%Y-%m-%d %H:%M:%S", t)
end

local function validate_multiuse_rand(rand)
	rand = rand:gsub("%s", "")
	if not rand:gmatch("^[a-zA-Z0-9+/]+=*$") then
		return nil
	end
	return rand
end

function getfpr(multiuse_rand)
	local r = validate_multiuse_rand(multiuse_rand)
	if not r then
		return nil
	end
	local f = io.popen("echo ".. r .." | epoint_dsakey -f", "r")
	if not f then
		return nil
	end
	local s = f:read()
	f:close()
	return s
end

local function getpubkey(multiuse_rand)
	local r = validate_multiuse_rand(multiuse_rand)
	if not r then
		return nil
	end
	local f = io.popen("echo ".. r .." | epoint_dsakey -a", "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

local function signdocument(multiuse_rand, doc, tmpfn)
	local r = validate_multiuse_rand(multiuse_rand)
	if not r then
		return nil
	end
	local f = io.popen("epoint_sign ".. r .." >"..tmpfn, "w")
	if not f then
		return nil
	end
	f:write(doc)
	f:close()
	f = io.open(tmpfn, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	os.remove(tmpfn)
	return s
end

-- returns nil in case of network or internal error
-- returns {} in case of client error
-- returns table with the certificate parameters in case of success
function obligation_transfer(multiuse_rand, target_fpr, value)
	local rnd = rnd12()
	local fpr = getfpr(multiuse_rand)
	if not fpr or #fpr == 0 then
		-- client error
		return {}
	end
	if fpr == target_fpr then
		-- TODO: hack, pretend that the transaction was successful
		return {VALUE=0, DIFFERENCE=0}
	end
	local tpl = obligation_transfer_template
	if not tpl then
		tpl = template_by_id("OBLIGATION_TRANSFER")
		if not tpl then
			return nil
		end
		obligation_transfer_template = tpl
	end
	local tplid = crypto.hexdigest("sha1", tpl)
	-- maturity/expiry: t+-20 min
	local t = os.time()
	local doc = tpl:gsub("$BENEFICIARY", target_fpr):gsub("$VALUE", value):gsub("$DRAWER", fpr):
		gsub("$DRAWEE", issuerfpr):gsub("$MATURITY_DATE", datestr(t-1200)):
		gsub("$EXPIRY_DATE", datestr(t+1200)):gsub("$DATE", datestr(t)):
		gsub("$REFERENCE_NUMBER", rnd):gsub("$NOTES", "N/A")
	doc = "Content-type: text/plain.epoint.obligation-transfer; charset=utf-8\n" ..
		"Document-template: " .. issuer .. "/template?ID=" .. tplid .. "\n\n" .. doc
	local signed = signdocument(multiuse_rand, doc, "/tmp/".. rnd)
	local keydata = getpubkey(multiuse_rand)
	if not signed or not keydata then
		return nil
	end
	local body, code = http.request(
		string.format("%s/action", issuer), "D="..urlencode(signed).."&KEYDATA="..urlencode(keydata))
	if code == 200 and body then
		return parse_message(body)
	elseif code ~= 404 then
		return nil
	end
	-- retry in case template has changed
	local newtpl = template_by_id("OBLIGATION_TRANSFER")
	if not newtpl then
		return nil
	elseif newtpl == tpl then
		-- client error
		return {}
	end
	obligation_transfer_template = newtpl
	return obligation_transfer(multiuse_rand, target_fpr, value)
end
