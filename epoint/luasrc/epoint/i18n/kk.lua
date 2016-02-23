module("epoint.i18n.kk", package.seeall)

-- Translation by Korlan Smagulova <estaykizi@gmail.com>

selfname = "Қазақша"

local translations = {
    ["Billing information"] = "Төлем мәліметтері",
    ["Save"] = "Сақтау",
    -- clear a field, some entered data?
    ["Clear"] = "Мәліметтерді өшіру",
    ["Name"] = "Аты-жөні",
    ["Address"] = "Мекен-жай",
    ["Important: cookies must be enabled for billing to work."] =
        "<strong>Қажетті ақпарат:</strong> төлем-шотты басып алу үшін cookies-терді қосқан жөн.",
    ["Error: cookies are disabled in your browser."] =
        "Қателік: сіздің браузеріңізде cookies рұқсат етілмеген, қосылмаған.",
    ["%d day"] = "%d күн",
    ["%d hour"] = "%d сағат",
    ["%d minute"] = "%d минут",
    ["Unlimited access"] = "Уақыты шексіз байланысқа қосылу",
    ["No access"] = "Қосылудан тыс, уақытыңыз жеткіліксіз",
    -- splash form
    ["Welcome!"] = "Қош келдіңіздер!",
    ["Payment"] = "Төлеу",
    ["Enter ePoint rand:"] = "ePoint rand кодын енгізіңіз:",
    ["After paying, it is safe to close the browser window."] =
        "Төлем жасағаннан кейін браузерді жабуға болады.",
    ["Rates"] = "Тарифтер",
    ["Per-minute"] = "1 минут үшін",
    ["Hourly"] = "1 сағат үшін",
    ["Daily"] = "1 күн үшін",
    ["Monthly"] = "айлық",
    ["Issuer of accepted RANDs:"] = "Rand-терді шығарушы тұлға:",
    ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
        "Шотты басып шығару үшін <a href='%s'>осында</a> басыңыз да, қажетті ақпаратты енгізіп, нысанды толтырыңыз.",
    ["Invoice"] = "Шот",
    ["Buyer:"] = "Сатып алушы:",
    ["Billing address:"] = "Сатып алушының мекен-жайы:",
    ["Click here to modify."] = "Өзгертулерді енгізу үшін осында басыңыз.",
    ["Customer support line:"] = "Техникалық қолдау қызметінің телефон нөмірі:",
    -- error messages
    -- ??? TODO
    ["Payment timestamp differs too much from current time. Please, check router's clock."] =
        "Payment timestamp differs too much from current time. Please, check router's clock.",
    ["Invalid payment"] = "Төлем қабылданбаған",
    ["Payment below minimum"] = "Төлем рұқсат етілген минималды сомадан кем",
    ["You are whitelisted"] = "Сіз рұқсат етілген қолданушылар тізіміндесіз",
    -- ???
    ["Timeout"] = "Уақыт өтіп кетті",
    ["Try to pay again"] = "Төлем іске асырылмаған, тағы да бір рет төлеп көріңіз",
    -- splash-redir
    ["Thank you!"] = "Рахмет!",
    ["Status"] = "Мәртебеңіз",
    ["You can log out here"] = "Сессияны аяқтау",
    ["You can now visit %s."] = "Енді %s қосылуға болады.",
    ["Remaining time:"] = "Қалған уақыт:",
    ["You can safely close this window."] =
        "Енді бұл веб-парақты жабу қауіпсіз.",
    ["Buy more time"] = "Қосымша уақытты сатып алу",
    ["You will be redirected to %s in a few seconds."] =
        "Бірнеше секундтың ішінде %s-ға қайтадан аударылып қосыласыз."
}

function translate(msgid, ...)
    return translations[msgid] or msgid
end
