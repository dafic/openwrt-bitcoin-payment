require("luci.sys")

local data = {}
local whitelisted = {}

local whitelist = luci.sys.exec("/usr/sbin/whitelist")
for line in string.gmatch(whitelist, "[^\n]+\n") do
	local addr = string.match(line, "^%s*([%x.:]+)")
	local comment = string.match(line, '#%s*(.*)$') or ""
	table.insert(data, { addr = addr, comment = comment })
	whitelisted[addr] = true
end

local form = SimpleForm("whitelist", "Whitelist")
form.reset = false

local table = form:section(Table, data)
table.addremove = true
table.template_addremove = "epoint/empty"
table:option(DummyValue, "addr", "MAC or IP address")
table:option(DummyValue, "comment", "Comment")

function table:parse(readinput)
	self.map.readinput = (readinput ~= false)
	local rm_prefix = "cbi.rts." .. self.config
	local removed = self.map:formvaluetable(rm_prefix)
	for k, v in pairs(removed) do
		local row = self.data[tonumber(k)]
		if row then
			os.execute("/usr/sbin/whitelist remove " .. row.addr)
		end
	end
end

local wan_devices = {}
for line in io.lines("/var/state/network") do
	local ifname = string.match(line, "network.wan.ifname%s*=%s*([%w%._-]+)")
	if ifname then
		wan_devices[ifname] = true
	end
	local devices = string.match(line, "network.wan.device%s*=%s*(.+)")
	if devices then
		for device in string.gmatch(devices, "[%w%._-]+") do
			wan_devices[device] = true
		end
	end
end

local hostname = {}
for line in io.lines("/var/dhcp.leases") do
	local addr, ip, name = string.match(line, "%d+%s+([%x:.]+)%s+([%x:.]+)%s+([^%s]+)")
	if name and name ~= "*" then
		hostname[addr] = name
	end
end

local newaddr = form:field(Value, "newaddr",
	"Add new MAC address (* -- your computer unless you're using SSL)")
local admin_ip = luci.http.getenv("REMOTE_ADDR")
local admin_addr = ""
for i, entry in ipairs(luci.sys.net.arptable()) do
	local addr = string.lower(entry["HW address"])
	local ip = entry["IP address"]
	if not wan_devices[entry["Device"]] and not whitelisted[addr] then
		local star = ""
		if ip == admin_ip then
			star = "* "
			admin_addr = addr
		end
		newaddr:value(addr, string.format("%s%s (%s%s)",
		  star, addr, ip, hostname[addr] and " "..hostname[addr] or ""))
	end
end

function newaddr:validate(value)
	return value:match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") or
	       value:match("^[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]$")
end

form:field(Value, "comment", "Comment")
--TODO: form:field(Flag, "roaming", "Roaming enabled")

-- TODO: error message in case of failure?
function form:handle(state, data)
	if state == FORM_VALID then
		if data.newaddr then
			local addr = string.lower(data.newaddr)
			local code = os.execute(string.format(
			  "/usr/sbin/whitelist add %s '%s%s'",
			  addr,
			  hostname[addr] and ("@"..hostname[addr].." ") or "",
			  string.gsub(data.comment or "", "'", "'\\''")))
			if code ~= 0 then
				return false
			end
		end
		luci.http.redirect(luci.http.getenv("REQUEST_URI"))
	end
	return true
end

return form
