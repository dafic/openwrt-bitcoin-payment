module("epoint.invoice.hu", package.seeall)
local tariff = require("epoint.tariff")
require("uci")

local header = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title>Számla</title>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8">
<style type="text/css">
* {font-family:Sherif; font-size:11px;}
table {border-collapse:collapse; margin-bottom:8px;}
table, th, td {border:1px solid black; text-align:center;}
td.sig {text-align:left; vertical-align:text-top; height:4em;}
hr {margin:2em;}
</style>
</style>
</head>
<body>
]]


-- TODO: long address -> does not fit on one page
local invoice = [[
<table border=1 width=100%>
<tr><th>számla<th>példány szám: {printcount}<th>sorszám: {sn}
</table>

<table border=1 width=100%>
<tr><th>Eladó<th>Vevő
<tr><td class="sig">{seller}<td class="sig">{payer}
</table>

<table border=1 width=100%>
<tr><th>A fizetés módja<th>A teljesítés időpontja<th>A számla kelte<th>Fizetési határidő
<tr><td>{method}<td>{date}<td>{date}<td>{date}
</table>

<table border=1 width=100%>
<tr><th>A szolgáltatás megnevezése<th>ÁFA kulcs
<th>Mennyiségi egység<th>Mennyiség<th>Egységár (ÁFA nélkül)<th>Érték (ÁFA nélkül)
<tr><td>{service}<td>{vat} %<td>{unit}<td>{amount}<td>{unitprice}<td>{price}
</table>

<table border=1 width=100%>
<tr><th>A számlaérték ÁFA nélkül<th>Az ÁFA összege ({vat} %)<th>A számla végösszege
<tr><td>{price}<td>{vatprice}<td>{fullprice} azaz {fullpricetext}
</table>
<p><small>A számla az ePoint Rendszerek kft. által fejlesztett ePoint HotSpot programmal készült.</small>
]]

local footer = [[
</body>
</html>
]]

-- TODO: is this avail in luci?
local function htmlesc(s)
	r = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\n", "<br>")
	return r
end

local function replace(s, vars)
	for k,v in pairs(vars) do
		s = s:gsub("{"..k.."}", htmlesc(tostring(v)))
	end
	return s
end

local function num2text(n)
	local t = {"egy","kettő","három","négy","öt","hat","hét","nyolc","kilenc","tíz"}
	t[0] = "nulla"
	t[20] = "húsz"
	t[30] = "harminc"
	t[40] = "negyven"
	t[50] = "ötven"
	t[60] = "hatvan"
	t[70] = "hetven"
	t[80] = "nyolcvan"
	t[90] = "kilencven"

	if t[n] then
		return t[n]
	elseif n < 20 then
		return "tizen" .. t[n % 10]
	elseif n < 30 then
		return "huszon" .. t[n % 10]
	elseif n < 100 then
		return t[n - n % 10] .. t[n % 10]
	end

	local s, m

	if n < 1000 then
		s = t[math.floor(n / 100)] .. "száz"
		m = n % 100
		if m > 0 then
			return s .. num2text(m)
		else
			return s
		end
	end

	if n < 1000000 then
		s = num2text(math.floor(n / 1000)) .. "ezer"
		m = n % 1000
		if m > 0 then
			-- actually no "-" is needed for n < 3000
			return s .. "-" .. num2text(m)
		else
			return s
		end
	end

	-- we assume n < 1000*1000*1000
	s = num2text(math.floor(n / 1000000)) .. "millió"
	m = n % 1000000
	if m > 0 then
		return s .. "-" .. num2text(m)
	else
		return s
	end
end


-- return price text, full price
local function getpricetext(price, curr)
	if curr == "HUF" then
		local n = math.floor(price)
		return string.format("%s forint", num2text(n)), string.format("%d HUF", n)
	elseif curr == "EUR" then
		local n1 = math.floor(price)
		local n2 = math.floor((price-n1)*100)
		return string.format("%s euró és %s cent", num2text(n1), num2text(n2)), string.format("%d.%02d EUR", n1, n2)
	else
		local n = math.floor(price)
		return string.format("%s %s", num2text(n), curr), string.format("%d %s", n, curr)
	end
end

local function getvars(t)
	local vat = tonumber(uci.get("epoint-invoice.config.vat")) or 0.25
	local price = t.value/(1 + vat)
	local dt = tariff.choose(t.payment)
	local unittime = {60, 3600, 3600*24, 3600*24*30}
	local unitname = {"perc", "óra", "nap", "hónap"}
	local unit, amount
	local fullpricetext, fullprice = getpricetext(t.value, t.unit)

	for i, v in pairs(unittime) do
		unit = i
		amount = dt/v
		if amount < 100 then
			break
		end
	end

	-- TODO: play with amount or play with unitprice.. +currency
	-- TODO: uci.get -> check nil?
	return {
		printcount="",
		sn=t.sn,
		seller=uci.get("epoint-invoice.config.seller") or "",
		payer=string.format("%s, %s", t.name, t.address),
		method=uci.get("epoint-invoice.config.method") or "",
		date=os.date("%Y-%m-%d", t.timestamp),
		service=uci.get("epoint-invoice.config.service") or "",
		unit=unitname[unit],
		amount=string.format("%.2f", amount),
		unitprice=string.format("%.2f %s", price/amount, t.unit),
		price=string.format("%.2f %s", price, t.unit),
		-- TODO: proper vat percent format
		vat=vat*100,
		vatprice=string.format("%.2f %s", t.value-price, t.unit),
		fullprice=fullprice,
		fullpricetext=fullpricetext
	}
end


function render(t)
	local vars = getvars(t)

	vars.printcount="1."
	local i1 = replace(invoice, vars)
	vars.printcount="2."
	local i2 = replace(invoice, vars)
	vars.printcount="3."
	local i3 = replace(invoice, vars)

	-- TODO: print at once
	return header .. i1 .. "<hr>" .. i2 .. "<hr>" .. i3 .. footer
end

