local m = Map("epoint", "User accounts")
local s = m:section(TypedSection, "user", "Users")
s.addremove = true
s.anonymous = true
s:option(Value, "login", "Login")
s:option(Value, "password", "Password").password = true

return m
