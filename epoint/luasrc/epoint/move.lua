module("epoint.move", package.seeall)

-- copy file from path from to path to
function copy(from, to)
	local r, e, c = io.open(from, 'r')
	if not r then
		return r, e, c
	end
	from = r
	r, e, c = io.open(to, 'w')
	if not r then
		from:close()
		return r, e, c
	end
	to = r
	while true do
		r, e, c = from:read(4096)
		if not r then
			if not e then
				r = true
			end
			break
		end
		r, e, c = to:write(r)
		if not r then
			break
		end
	end
	-- TODO: can fail
	from:close()
	to:close()
	return r, e, c
end

-- Robust rename even between different filesystems
function move(from, to, totmp)
	-- TODO: use util.rename() ?
	local r, e, c = os.rename(from, to)
	if not r and c == 18 then
		-- retry with copy in case of EXDEV (c == 18) error code
		if totmp == nil then
			totmp = to
		end
		r, e, c = copy(from, totmp)
		if not r then
			return r, e, c
		end
		r, e, c = os.rename(totmp, to)
		if not r then
			if totmp ~= to then
				os.remove(totmp)
			end
			return r, e, c
		end
		r, e, c = os.remove(from)
	end
	return r, e, c
end
