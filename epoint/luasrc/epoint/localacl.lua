-- persistent acl file manipulation module

module("epoint.localacl", package.seeall)

local util = require("epoint.util")
local move = require("epoint.move")
require("epoint.scope")

local lockfile = "/var/lock/epoint.acl"
local aclfile = "/etc/epoint-local.acl"
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

function checkaddr(addr)
	return addr and (
	   addr:match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") or
	   addr:match("^[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]$"))
end

-- return nil if comment
-- return {addr = nil} if bad format
local function parseline(line)
	local s, comment = line:match("^([^#]*)#%s*(.*)$")
	if s and s:match("^%s*$") then
		return nil
	end
	if not comment then
		comment = ''
		s = line
	end
	local addr, expire = s:match("^%s*([%x:.]+)%s*(%d*)")
	if not checkaddr(addr) then
		addr = nil
	end
	return { addr = addr, expire = tonumber(expire), comment = comment }
end

-- keep those lines of acl where pred returns true
-- caller should hold exclusive acl lock
local function filter(acl, pred)
	local changed = false
	local tmpfile = "/var/epoint-local.acl.tmp"
	with_file(io.open(tmpfile, "w"), function(tmp)
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
		-- TODO: can fail, but we don't care for now
		move.move(tmpfile, acl)
	end
	return changed
end

-- return {addr, expire} or nil
-- addr must be lowercase (when mac)
-- caller should hold shared acl lock
local function search(addr)
	local f = io.open(aclfile, "r")
	if not f then
		return nil
	end
	return with_file(f, function(f)
		for line in f:lines() do
			local entry = parseline(line)
			if entry and entry.addr and entry.addr:lower() == addr then
				return entry
			end
		end
	end)
end

local function date(t)
	return os.date("%Y-%m-%d %H:%M:%S", t)
end

local function writeentry(f, addr, expire, comment)
	if not checkaddr(addr) then
		-- TODO: less fatal error
		error('acl writeentry: bad addr "'.. addr ..'"')
	end
	comment = comment or (expire and date(expire) or '')
	expire = expire or ''
	f:write(string.format("%s %s # %s\n", addr, expire, comment))
end

-- extern

function refresh()
	local t = os.time()
	return with_lock("x", function()
		return filter(aclfile, function(e)
			return not e.expire or e.expire > t
		end)
	end)
end

function remove(addr)
	addr = addr:lower()
	return with_lock("x", function()
		return filter(aclfile, function(e)
			return e.addr:lower() ~= addr
		end)
	end)
end

-- entries with unlimited access for whitelist
function unlimited()
	return with_lock("s", function()
		local f = io.open(aclfile, "r")
		local t = {}
		if not f then
			return t
		end
		return with_file(f, function(f)
			for line in f:lines() do
				local entry = parseline(line)
				if entry and entry.addr and not entry.expire then
					t[entry.addr] = entry
				end
			end
			return t
		end)
	end)
end

-- topup addr with dt time (t is now)
-- return false if whitelisted, otherwise true
function topup(addr, t, dt, comment)
	addr = addr:lower()
	return with_lock("x", function()
		local entry = search(addr)

		-- new addr
		if not entry then
			t = dt and t+dt or nil
			with_file(io.open(aclfile, "a"), function(f)
				writeentry(f, addr, t, comment)
			end)
			return true
		end

		-- whitelisted addr
		if not entry.expire then
			return true
		end

		-- topup old rule with dt
		t = dt and entry.expire+dt or nil
		filter(aclfile, function(e)
			return e.addr:lower() ~= addr
		end)
		with_file(io.open(aclfile, "a"), function(f)
			writeentry(f, addr, t, comment)
		end)
		return true
	end)
end
