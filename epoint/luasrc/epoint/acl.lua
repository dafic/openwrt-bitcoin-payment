--[[
Copyright (C) 2010 ePoint Systems Ltd

acl file manipulation module

(multiuse) acl format:
	<addr> <expire> <rand> # comment

extra acl format:
	<addr> [<expire> [...] ] # comment

comments and invalid entries are discarded/dropped
expire must be valid unix time

the two expires are very different:
first one is periodically updated until the rand
runs out of epoints, the second is a real expiration

this module does not edit extra acl files
they can be registered in uci and are treated
as external whitelists

if expire is missing from an extra acl that means
infinite access
]]--

module("epoint.acl", package.seeall)

local util = require("epoint.util")
require("epoint.scope")
require("uci")

local aclfile = "/var/epoint.acl"
local acltmpfile = "/var/epoint.acl.tmp"
local lockfile = "/var/lock/epoint.acl"
local bracket = epoint.scope.bracket
local with_file = epoint.scope.with_file

-- split comma separated values
local function split(s)
	local t = {}
	for v in s:gmatch("([^,]+)") do
		table.insert(t,v)
	end
	return t
end

function extraacls()
	local s = uci.get("epoint.config.extraacls") or ""
	return split(s)
end

local function with_lock(mode, action)
	return bracket(
		io.open(lockfile, "w"),
		io.close,
		function(lock)
			util.flock(lock, mode)
			return action()
		end)
end

function checkaddr(addr)
	return addr and (
	   addr:match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") or
	   addr:match("^[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]$"))
end

-- return nil if comment
-- return {addr = nil} if bad format
local function parseline(line)
	local s = line:gsub("#.*$", "")
	if s == "" then
		return nil
	end
	local addr, expire, rand = s:match("^%s*([%x:.]+)%s+(%d+)%s*([^%s]*)%s*$")
	-- validate mac and ip addr
	if not checkaddr(addr) then
		addr = nil
	end
	return { addr = addr, expire = tonumber(expire), rand = rand }
end

local function writeentry(f, e)
	return f:write(string.format("%s %s %s\n", e.addr, e.expire, e.rand))
end

-- return addr, expire entries
local function load()
	local f = io.open(aclfile, "r")
	if not f then
		return {}
	end
	return with_file(f, function(f)
		local result = {}
		for line in f:lines() do
			local entry = parseline(line)
			if entry and entry.addr then
				result[entry.addr] = entry
			end
		end
		return result
	end)
end

-- update addr, expire entries
local function replace(entries)
	if not with_file(io.open(acltmpfile, "w"), function(f)
		for a, e in pairs(entries) do
			if not writeentry(f, e) then
				return
			end
		end
		return true
	end) then
		return
	end
	if not os.rename(acltmpfile, aclfile) then
		return
	end
	return true
end

local function find(acl, addr)
	local f = io.open(acl, "r")
	if not f then
		return
	end
	return with_file(f, function(f)
		for line in f:lines() do
			local s = line:gsub("#.*$", "")
			local a, expire = s:match("^%s*([%x:.]+)%s*(%d*)")
			if a and a:lower() == addr then
				return true, tonumber(expire)
			end
		end
	end)
end

function read()
	return with_lock("s", load)
end

function update(func)
	return with_lock("x", function()
		local entries = load()
		func(entries)		
		if not entries then
			return
		end
		return replace(entries)
	end)
end

-- TODO: extra entries..
function extraaccess(addr)
	return with_lock("s", function()
		for i,acl in ipairs(extraacls()) do
			local ok, expire = find(acl, addr)
			if ok then
				return ok, expire
			end
		end
	end)
end

-- TODO: extra entries..
function extraentries(addr)
	return with_lock("s", function()
		local t = {}
		for i,acl in ipairs(extraacls()) do
			local f = io.open(acl, "r")
			if f then
				with_file(f, function(f)
					for line in f:lines() do
						local s = line:gsub("#.*$", "")
						local a, expire = s:match("^%s*([%x:.]+)%s*(%d*)")
						if t[a] == nil then
							t[a] = {addr=a, expire=tonumber(expire)}
						end
					end
				end)
			end
		end
		return t
	end)
end

function hasaccess(addr)
	addr = addr:lower()
	local ok, expire = extraaccess(addr)
	if ok then
		return ok, expire
	end
	local t = read()
	local e = t[addr]
	if e then
		return true, e.expire, e.rand
	end
	return false
end

function topup(addr, t, dt, rand)
	addr = addr:lower()
	-- TODO: extraaccess + topup might make sense together..
	if extraaccess(addr) then
		return true
	end
	return update(function(entries)
		if entries[addr] then
			entries[addr].expire = entries[addr].expire + dt
		else
			entries[addr] = {addr=addr, expire = t+dt}
		end
		if rand then
			entries[addr].rand = rand
		end
	end)
end

-- TODO: move this to somewhere else +luci has arptable functions..
function getaddr(remote_addr)
	return with_file(io.open("/proc/net/arp", "r"), function(f)
		for line in f:lines() do
			local ip, mac = line:match("^%s*([^%s]+)%s+[^%s]+%s+[^%s]+%s+([^%s]+)")
			if ip == remote_addr then
				return mac:lower()
			end
		end
		return remote_addr
	end)
end

-- mac to ip mappings
function arptable()
	return with_file(io.open("/proc/net/arp", "r"), function(f)
		local t = {}
		f:read()
		for line in f:lines() do
			local ip, mac = line:match("^%s*([^%s]+)%s+[^%s]+%s+[^%s]+%s+([^%s]+)")
			t[mac:lower()] = ip
		end
		return t
	end)
end
