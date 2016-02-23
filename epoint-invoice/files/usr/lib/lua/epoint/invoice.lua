module("epoint.invoice", package.seeall)
local protocol = require("luci.http.protocol")
local util = require("epoint.util")

-- this modul implement utils for parsing billing log

local billinglog = "/etc/epoint/billing.log"

-- call action with file opened for reading, return the result of action or nil
local function process(file, action)
	local f = io.open(file)
	if not f then
		return nil
	end
	util.flock(f, "s")
	local r = {pcall(action, f)}
	io.close(f)
	if not r[1] then
		return nil
	end
	return r[2]
end

-- TODO: efficient filesize() for binary search..
local function fsize(f)
	local current = f:seek()
	local size = f:seek("end")
	f:seek("set", current)
	return size
end

local function fixentry(t)
	if not t or not t.name or not t.address or not t.timestamp or
	   not t.payment or not t.currency or not t.sn then
		return nil
	end
	t.timestamp = tonumber(t.timestamp)
	t.payment = tonumber(t.payment)
	i,j = t.currency:find(" ")
	if not i then
		return nil
	end
	t.value = tonumber(t.currency:sub(1,i-1))
	t.unit = t.currency:sub(j+1)
	t.sn = tonumber(t.sn)
	return t
end

-- TODO: we assume an entry is < 4K

-- bisect
local function findsn(f, sn)
	local hi = fsize(f)
	local lo = 0
	local pos = 0
	local cursn = 0
	while true do
		-- stop bisect if the target is close
		if cursn < sn and cursn + 10 > sn then
			break
		end
		if hi - lo < 4096 then
			f:seek("set", lo)
			break
		end

		pos = math.floor((hi + lo)/2)
		f:seek("set", pos)
		-- read a (probably) incomplete line
		local s = f:read("*l")
		-- read a complete line
		local line = f:read("*l")
		if line then
			local entry = protocol.urldecode_params(line)
			if entry then
				cursn = tonumber(entry.sn)
				if cursn < sn then
					lo = pos + s:len() + line:len() + 2
				elseif cursn > sn then
					hi = pos
				else
					return fixentry(entry)
				end
			end
		else
			hi = pos
		end
	end
	-- linear search()
	for line in f:lines() do
		local entry = protocol.urldecode_params(line)
		if entry then
			cursn = tonumber(entry.sn)
			if cursn == sn then
				return fixentry(entry)
			elseif cursn > sn then
				return nil
			end
		end
	end
	return nil
end

-- bisect
local function findtime(f, t)
	local hi = fsize(f)
	local lo = 0
	local pos = 0
	local curt = 0
	while true do
		-- stop bisect if the target is close
		if hi - lo < 4096 then
			f:seek("set", lo)
			break
		end

		pos = math.floor((hi + lo)/2)
		f:seek("set", pos)
		-- read a (probably) incomplete line
		local s = f:read("*l")
		-- read a complete line
		local line = f:read("*l")
		if line then
			local entry = protocol.urldecode_params(line)
			if entry then
				curt = tonumber(entry.timestamp)
				if curt < t then
					lo = pos + s:len() + line:len() + 2
				elseif curt > t then
					hi = pos
				else
					return fixentry(entry)
				end
			end
		else
			hi = pos
		end
	end
	-- linear search
	local entry = nil
	for line in f:lines() do
		entry = protocol.urldecode_params(line)
		if entry then
			curt = tonumber(entry.timestamp)
			if curt == t or curt > t then
				return fixentry(entry)
			else
				fixentry(entry)
			end
		end
	end
	return entry
end

-- get entry by sn
function getsn(sn)
	sn=tonumber(sn)
	return process(billinglog, function(f)
		return findsn(f, sn)
	end)
end

function getfirst()
	return process(billinglog, function(f)
		local line = f:read("*l")
		if line then
			return fixentry(protocol.urldecode_params(line))
		end
		return nil
	end)
end

function getlast()
	return process(billinglog, function(f)
		local entry = nil
		local siz = fsize(f)
		if siz > 4096 then
			f:seek("set", siz-4096)
			f:read("*l")
		end
		for line in f:lines() do
			local e = protocol.urldecode_params(line)
			if e and e.sn then
				entry = e
			end
		end
		return fixentry(entry)
	end)
end

-- TODO: return 0 if not found?
function gettimesn(time)
	return process(billinglog, function(f)
		entry = findtime(f, time)
		if entry then
			return tonumber(entry.sn)
		else
			return 0
		end
	end)
end

-- n entries starting from sn
function getsnrange(sn, n)
	sn=tonumber(sn)
	n=tonumber(n)
	return process(billinglog, function(f)
		local e = findsn(f, sn)
		if not e then
			return {}
		end
		local r = {e}
		local i = 1
		if n == 1 then
			return r
		end
		for line in f:lines() do
			e = protocol.urldecode_params(line)
			table.insert(r, fixentry(e))
			i = i + 1
			if i >= n then
				break
			end
		end
		return r
	end)
end

-- n entries starting from t
function gettimerange(t, n)
	return process(billinglog, function(f)
		local e = findtime(f, t)
		if not e then
			return {}
		end
		local r = {e}
		local i = 1
		if n == 1 then
			return r
		end
		for line in f:lines() do
			e = protocol.urldecode_params(line)
			table.insert(r, fixentry(e))
			i = i + 1
			if i >= n then
				break
			end
		end
		return r
	end)
end

