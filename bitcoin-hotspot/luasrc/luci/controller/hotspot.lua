
module("luci.controller.epoint", package.seeall)

function index()
	entry({"admin", "epoint"}, call("action_main"), "ePoint").index = true
	entry({"admin", "epoint", "status"}, call("action_main"), "Management")
	entry({"admin", "epoint", "templates"}, call("action_editor"), "Template editor")
	entry({"admin", "epoint", "tariffs"}, call("action_tariff_editor"), "Tariff editor")
	entry({"admin", "epoint", "whitelist"}, form("epoint/whitelist"), "MAC address whitelist")
	entry({"admin", "epoint", "accounts"}, cbi("epoint/accounts"), "Manage user accounts")
	entry({"admin", "epoint", "upload"}, call("upload"), "Upload RANDs")
end

function action_main()
	local protocol = require("epoint.protocol")
	require("luci.fs")
	require("uci")

	local is_running = luci.fs.access("/var/run/epoint")
	if luci.http.formvalue("switch") then
		if is_running then
			os.execute("/etc/init.d/epoint stop")
			os.execute("/etc/init.d/epoint disable")
		else
			os.execute("/etc/init.d/epoint enable")
			os.execute("/etc/init.d/epoint start")
		end
	end
	is_running = luci.fs.access("/var/run/epoint")

	local new_target = ""
	local new_targetrand = ""
	local invalid_target = false
	local invalid_targetrand = false
	if luci.http.formvalue("submit-rand") then
		new_targetrand = luci.http.formvalue("targetrand")
		new_targetrand = string.gsub(new_targetrand, "%s", "")
		if not string.match(new_targetrand, "^[a-zA-Z0-9/+]+=*$") then
			invalid_targetrand = true
		else
			t = protocol.getfpr(new_targetrand)
			if not t then
				invalid_targetrand = true
			else
				uci.set("epoint.config.target=" .. t)
				uci.commit("epoint")
				new_targetrand = ""
			end
		end
	elseif luci.http.formvalue("submit") then
		new_target = luci.http.formvalue("target")
		new_target = string.upper(string.gsub(new_target, "[%s-.,:]", ""))
		if not string.match(new_target, "^%x+$") and #new_target ~= 40 then
			invalid_target = true
		else
			uci.set("epoint.config.target=" .. new_target)
			uci.commit("epoint")
			new_target = ""
		end
	elseif luci.http.formvalue("reset") then
		uci.delete("epoint.config.target")
		uci.commit("epoint")
	end

	local target = uci.get("epoint.config.target")
	local total = 0
	local target_verified = false
	if target then
		c = protocol.verify(target)
		if c then
			target_verified = true
		end
		if target_verified then
			total = c.value
		elseif string.match(target,"^%x+$") then
			-- TODO: invalid?
			target_verified = true
			total = 0
		end
	end

	local invalid_tariff = false
	local new_tariff = ""
	if luci.http.formvalue("submit-tariff") then
		new_tariff = luci.http.formvalue("tariff")
		new_tariff = tonumber(new_tariff)
		if new_tariff and new_tariff > 0 and math.floor(new_tariff) == new_tariff then
			uci.set("epoint.config.tariff=" .. new_tariff)
			uci.commit("epoint")
			new_tariff = ""
		else
			invalid_tariff = true
		end
	end
	local tariff = uci.get("epoint.config.tariff")

	if luci.http.formvalue("submit-lang") then
		local interface_lang = luci.http.formvalue("iface-language")
		-- default "please choose" option has value="0"
		if interface_lang ~= "0" then
			uci.set("epoint.config.interface_lang=" .. interface_lang)
			uci.commit("epoint")
		end
	end

	luci.template.render("epoint/main",
		{ target = target, total = total, target_verified=target_verified, is_running = is_running,
		  new_tariff = new_tariff, invalid_tariff = invalid_tariff, tariff = tariff,
		  new_target = new_target, invalid_target = invalid_target,
		  new_targetrand = new_targetrand, invalid_targetrand = invalid_targetrand })
end

function upload()
	luci.http.redirect("/cgi-bin/epoint/upload")
end

function action_editor()
	require("luci.fs")
	require("luci.util")
	
	local luci_template_dir = "/usr/lib/lua/luci/view/epoint/client"
	local resources_dir = "/www/epoint-static"

	local logo_path = "/www/epoint-static/mylogo.jpg"
	local logo_file
	local import_cmd = string.format("tar xz -C / %s %s",
		luci_template_dir:sub(2), resources_dir:sub(2))
	local import_pipe
	luci.http.setfilehandler(function(meta, chunk, eof)
		if meta and meta.name == "logo" then
			if chunk and not logo_file then
				logo_file = io.open(logo_path, "w")
			end
			if chunk and logo_file then
				logo_file:write(chunk)
			end
			if eof and logo_file then
				logo_file:close()
			end
		elseif meta and meta.name == "branding" then
			if chunk and not import_pipe then
				import_pipe = io.popen(import_cmd, "w")
			end
			if chunk and import_pipe then
				import_pipe:write(chunk)
			end
			if eof and import_pipe then
				import_pipe:close()
			end
		end
	end)
	
	local files = {}
	for i, file in ipairs(luci.fs.dir(luci_template_dir)) do
		if file ~= "." and file ~= ".." then
			local path = luci_template_dir .. "/" .. file
			files[path] = file
		end
	end

	if luci.http.formvalue("export") then
		local backup_cmd = string.format("tar cz -C / %s %s",
			luci_template_dir, resources_dir)
		local fd = io.popen(backup_cmd, "r")
		luci.http.header("Content-Disposition", "attachment; filename=branding.tar.gz")
		luci.http.prepare_content("application/x-targz")
		luci.ltn12.pump.all(luci.ltn12.source.file(fd), luci.http.write)
	end
	
	local file = luci.http.formvalue("file")
	local submitted = file and luci.http.formvalue("file-selected") ~= "1"
	if not files[file] then
		for k, v in pairs(files) do
			file = k
			break
		end
		submitted = false
	end
	if submitted then
		luci.fs.writefile(file,
			string.gsub(luci.http.formvalue("content"), "\r", ""))
	end
	local content = luci.fs.readfile(file)
	
	luci.template.render("epoint/editor", {
		files = files, content = content, selected_file = file })
end

function action_tariff_editor()
	require("luci.fs")
	require("luci.util")

	local file = "/etc/epoint/tariffs"
	local content = luci.http.formvalue("content")
	if content then
		luci.fs.writefile(file,
			string.gsub(luci.http.formvalue("content"), "\r", ""))
	end
	content = luci.fs.readfile(file)
	luci.template.render("epoint/tariff-editor", {
		content = content })
end
