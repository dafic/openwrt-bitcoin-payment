module("epoint.i18n.en", package.seeall)

selfname = "English"

local function plural(singularform, pluralform)
    return function(n)
        if n == 1 then
            return singularform
        else
            return pluralform
        end
    end
end

local translations = {
    ["Important: cookies must be enabled for billing to work."] =
       "<strong>Important:</strong> cookies must be enabled for billing to work.";
    ["%d day"] = plural("%d day", "%d days"),
    ["%d hour"] = plural("%d hour", "%d hours"),
    ["%d minute"] = plural("%d minute", "%d minutes")
}

function translate(msgid, ...)
    local result = translations[msgid]
    if type(result) == "function" then
        return result(...)
    elseif result then
        return result
    else
        return msgid
    end
end
