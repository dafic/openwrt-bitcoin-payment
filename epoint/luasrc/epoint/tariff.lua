module("epoint.tariff", package.seeall)

require("epoint.scope")
util=require("epoint.util")
local with_file = epoint.scope.with_file
tariffs = "/etc/epoint/tariffs"

-- calls func(time, amount) for each line
local function parse(func)
	return with_file(io.open(tariffs, "r"), function(f)
		local ret
		for line in f:lines() do
			line = string.gsub(line, "#.*$", "")
			local time, amount = string.match(line, "%s*(%d+)%s+(%d+)")
			if time and amount then
				time = tonumber(time)
				amount = tonumber(amount)
				ret = func(time, amount)
				if ret then
					return ret
				end
			end
		end
		return nil
	end)
end

-- return time for given payment
function time(payment)
	local t = parse(function(t, p)
		if payment >= p then
			-- util.toint makes sure time is treated internally as integer
			-- but if its input cannot be represented then it returns 0
			return util.toint(math.ceil(t * payment / p))
		end
	end)
	return t or 0
end

-- required payment for a given time
function payment(time)
	local lastp
	local pay = parse(function(t, p)
		if time >= t then
			p = util.toint(math.ceil(p * time / t))
			if lastp and p > lastp then
				return lastp
			end
			return p
		end
		lastp = p
	end)
	return pay or lastp
end
