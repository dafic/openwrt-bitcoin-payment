-- acl file manipulation module

module("epoint.fixip.acl", package.seeall)

local tariff = require("epoint.fixip.tariff")
local util = require("epoint.util")
local move = require('epoint.move')
require("epoint.scope")

local lockfile = "/var/lock/epoint-fixip.acl"
local bracket = epoint.scope.bracket
local with_file = epoint.scope.with_file

local function with_lock(mode, action)
	return bracket(
		io.open(lockfile, "w"),
		io.close,
		function(lock)
			util.flock(lock, mode)
			return action()
		end)
end

-- return nil if comment
-- return {addr = nil} if bad format
local function parseline(line)
	local s = line:gsub("#.*$", "")
	if s == "" then
		return nil
	end
	local addr, expire = s:match("^%s*([%x:.]+)%s*(%d*)%s*$")
	-- validate mac and ip addr
	if addr and
	   not addr:match("^[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]$") then
		addr = nil
	end
	return { addr = addr, expire = tonumber(expire) }
end

-- keep those lines of acl where pred returns true
-- caller should hold exclusive acl lock
local function filter(acl, pred)
	local changed = false
	local tmpfile = "/var/epoint-fixip.acl.tmp"
	with_file(io.open(tmpfile, "w"), function(tmp)
		-- TODO: touch /var/epoint.* in init,update,..?
		local f = io.open(acl, "r")
		if not f then
			return
		end
		with_file(f, function(f)
			for line in f:lines() do
				local entry = parseline(line)
				if not entry then
					-- comment or empty line
					tmp:write(line .. "\n")
				elseif not entry.addr then
					-- bad rule
					tmp:write("# " .. line .. "\n")
					changed = true
				elseif pred(entry) then
					-- keep rule
					tmp:write(line .. "\n")
				else
					-- drop rule
					changed = true
				end
			end
		end)
	end)
	if changed then
		move.move(tmpfile, acl)
	end
	return changed
end

-- search addr in all acl files, return {addr, expire, aclfile}
-- caller should hold shared acl lock
local function search(addr)
	local fs = tariff.aclfiles()
	for _, acl in ipairs(fs) do
		local e = with_file(io.open(acl, "r"), function(f)
			for line in f:lines() do
				local entry = parseline(line)
				if entry and entry.addr and entry.addr:lower() == addr then
					entry.aclfile = acl
					return entry
				end
			end
			return nil
		end)
		if e then
			return e
		end
	end
end

local function date(t)
	return os.date("%Y-%m-%d %H:%M:%S", t)
end

local function writeentry(f, addr, expire)
	-- note: %s may produce 1.2e9 format if expire is internally float
	f:write(string.format("%s %s # %s\n", addr, expire, date(expire)))
end

-- extern

-- drop older entries than t from all acl files
-- return true if any of the files were changed
function dropold(t)
	local changed = false
	with_lock("x", function()
		local fs = tariff.aclfiles()
		for _, acl in ipairs(fs) do
			if filter(acl, function(e)
				return not e.expire or e.expire > t
			end) then
				changed = true
			end
		end
	end)
	return changed
end

-- search addr in all acl files
-- return hasaccess, expiretime, aclfile
function hasaccess(addr)
	local entry = with_lock("s", function()
		return search(addr)
	end)
	if entry then
		return true, entry.expire, entry.aclfile
	end
	return false
end

-- TODO: complicated arguments.. should come from tariff
-- topup addr with dt time (t is now, the rule should go in the acl file)
-- return false if whitelisted, otherwise true
function topup(addr, t, dt, acl)
	addr = addr:lower()
	return with_lock("x", function()
		local entry = search(addr)

		-- new addr
		if not entry then
			with_file(io.open(acl, "a"), function(f)
				writeentry(f, addr, t+dt)
			end)
			return true
		end

		-- whitelisted addr
		if not entry.expire then
			return false
		end

		-- topup old rule with dt
		t = entry.expire
		acl = entry.aclfile
		filter(acl, function(e)
			return e.addr ~= addr
		end)
		with_file(io.open(acl, "a"), function(f)
			writeentry(f, addr, t+dt)
		end)
		return true
	end)
end

