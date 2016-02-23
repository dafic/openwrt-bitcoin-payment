module("epoint.fixip.tariff", package.seeall)

require("epoint.scope")
util=require("epoint.util")

local with_file = epoint.scope.with_file

tariffs = "/etc/tariffs-fixip"
default_acl = "/etc/epoint-fixip.acl"

-- calls func(time, amount, acl, roam) for each line
local function parse(func)
    return with_file(io.open(tariffs, "r"), function(f)
        local ret
        for line in f:lines() do
            line = string.gsub(line, "#.*$", "")
            local time, amount, acl = string.match(line,
                "%s*(%d+)%s+(%d+)%s*([^%s]*)")
            if time and amount then
                time = tonumber(time)
                amount = tonumber(amount)
                ret = func(time, amount, acl)
                if ret then
                    return ret
                end
            end
        end
        return nil
    end)
end

-- return (time, aclfile, roamfile) for given payment
function choose(payment)
    local aclfile = default_acl
    local r = parse(function(time, amount, acl)
        if #acl > 0 then
            aclfile = acl
        end
        if payment >= amount then
            -- util.toint makes sure time is treated internally as integer
            -- can dangerous to use: if its input cannot be represented then it returns 0
            return {time = util.toint(math.ceil(time * payment / amount)), acl = aclfile}
        end
    end)
    if r then
        return r.time, r.acl
    end
    return 0, nil
end

-- return acl files listed in tariffs
function aclfiles()
    local t = {}
    local set = {}
    parse(function(time, amount, acl)
        if #acl > 0 then
            if not set[acl] then
                set[acl] = true
                table.insert(t, acl)
            end
        elseif #t == 0 then
            set[default_acl] = true
            table.insert(t, default_acl)
        end
    end)
    return t
end

