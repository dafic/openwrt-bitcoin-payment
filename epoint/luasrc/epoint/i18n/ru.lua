module("epoint.i18n.ru", package.seeall)

selfname = "Русский"

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
    ["Billing information"] = "Платежная информация",
    ["Save"] = "Сохранить",
    ["Clear"] = "Очистить",
    ["Name"] = "Имя",
    ["Address"] = "Адрес",
    ["Important: cookies must be enabled for billing to work."] =
        "<strong>Важно:</strong> для работы биллинга cookies должны быть разрешены.",
    ["Error: cookies are disabled in your browser."] =
        "Ошибка: в вашем браузере отключены cookies.",
    ["%d day"] = plural("%d день", "%d дня", "%d дней"),
    ["%d hour"] = plural("%d час", "%d часа", "%d часов"),
    ["%d minute"] = plural("%d минута", "%d минуты", "%d минут"),
    ["Unlimited access"] = "Неограниченный доступ",
    ["No access"] = "Нет доступа",
    -- splash form
    ["Welcome!"] = "Добро пожаловать!",
    ["Payment"] = "Оплата",
    ["Enter ePoint rand:"] = "Введите рэнд ePoint:",
    ["After paying, it is safe to close the browser window."] =
        "После оплаты окно браузера можно закрыть.",
    ["Rates"] = "Расценки",
    ["Per-minute"] = "За минуту",
    ["Hourly"] = "За час",
    ["Daily"] = "За день",
    ["Monthly"] = "За месяц",
    ["Issuer of accepted RANDs:"] = "Эмитент принимаемых рэндов:",
    ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
        "Если вы хотите получить распечатанный счет, нажмите <a href='%s'>сюда</a>, чтобы заполнить форму.",
    ["Invoice"] = "Счет",
    ["Buyer:"] = "Покупатель:",
    ["Billing address:"] = "Адрес:",
    ["Click here to modify."] = "Нажмите сюда, чтобы изменить.",
    ["Customer support line:"] = "Телефон техподдержки:",
    -- error messages
    ["Payment timestamp differs too much from current time. Please, check router's clock."] =
        "Отметка времени платежа сильно отличается от текущего времени. Пожалуйста, проверьте внутренние часы роутера.",
    ["Invalid payment"] = "Платеж отклонен",
    ["Payment below minimum"] = "Платеж меньше минимального",
    ["You are whitelisted"] = "Вы в белом списке",
    ["Timeout"] = "Время ожидания истекло",
    ["Try to pay again"] = "Попробуйте оплатить снова",
    -- splash-redir
    ["Thank you!"] = "Спасибо!",
    ["Status"] = "Статус",
    ["You can log out here"] = "Завершение сессии",
    ["You can now visit %s."] = "Переход на страницу %s.",
    ["Remaining time:"] = "Оставшееся время:",
    ["You can safely close this window."] =
        "Эту страницу можно безопасно закрыть.",
    ["Buy more time"] = "Купить дополнительное время",
    ["You will be redirected to %s in a few seconds."] =
        "Через несколько секунд вы будете перенаправлены на %s."
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
