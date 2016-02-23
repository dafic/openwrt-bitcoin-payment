module("epoint.i18n.uk", package.seeall)

selfname = "Українська"

-- form1 - одна сепулька
-- form2 - две сепульки
-- form3 - пять сепулек
local function plural(form1, form2, form3)
    return function(n)
        if n % 10 > 4 or n % 10 == 0 or (n % 100 > 10 and n % 100 < 20) then
            return form3
        elseif n % 10 == 1 then
            return form1
        else
            return form2
        end
    end
end

local translations = {
    ["Billing information"] = "Інформація щодо рахунку",
    ["Save"] = "Зберегти",
    ["Clear"] = "Видалити",
    ["Name"] = "Ім'я",
    ["Address"] = "Адреса",
    ["Important: cookies must be enabled for billing to work."] =
        "<strong>Важливо:</strong> для роботи білингу cookies повинні дозволятися.",
    ["Error: cookies are disabled in your browser."] =
        "Помилка: у вашому браузері відключені cookies.",
    ["%d day"] = plural("%d день", "%d дня", "%d днів"),
    ["%d hour"] = plural("%d година", "%d години", "%d годин"),
    ["%d minute"] = plural("%d хвилина", "%d хвилини", "%d хвилин"),
    ["Unlimited access"] = "Необмежений доступ",
    ["No access"] = "Немає доступу",
    -- splash form
    ["Welcome!"] = "Вітаємо!",
    ["Payment"] = "Оплата",
    ["Enter ePoint rand:"] = "Введіть ренд ePoint:",
    ["After paying, it is safe to close the browser window."] =
        "Після оплати вікно браузера можна закрити.",
    ["Rates"] = "Розцінки",
    ["Per-minute"] = "За хвилину",
    ["Hourly"] = "За годину",
    ["Daily"] = "За день",
    ["Monthly"] = "За місяць",
    ["Issuer of accepted RANDs:"] = "Емітент прийнятних рендів:",
    ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
        "Якщо Ви бажаєте отримати роздрукований рахунок, натисніть <a href='%s'>тут</a>, щоб заповнити форму.",
    ["Invoice"] = "Рахунок",
    ["Buyer:"] = "Покупець:",
    ["Billing address:"] = "Адреса:",
    ["Click here to modify."] = "Натисніть тут, щоб внести зміни.",
    ["Customer support line:"] = "Телефон технічної підтримки:",
    -- error messages
    ["Payment timestamp differs too much from current time. Please, check router's clock."] =
        "Зазначений час оплати значно відрізняється від поточного часу. Будь-ласка, перевірте внутрішній годинник роутера.",
    ["Invalid payment"] = "Оплату відхилено",
    ["Payment below minimum"] = "Оплата менша мінімальної",
    ["You are whitelisted"] = "Ви у білому списку",
    ["Timeout"] = "Час очікування закінчився",
    ["Try to pay again"] = "Спробуйте оплатити знову",
    -- splash-redir
    ["Thank you!"] = "Дякуємо!",
    ["Status"] = "Статус",
    ["You can log out here"] = "Закінчення сесії",
    ["You can now visit %s."] = "Перехід на сторінку %s.",
    ["Remaining time:"] = "Залишок часу:",
    ["You can safely close this window."] =
        "Цю сторінку можна безпечно закрити.",
    ["Buy more time"] = "Придбати додатковий час",
    ["You will be redirected to %s in a few seconds."] =
        "За кілька секунд Вас буде перенаправлено на %s."
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
