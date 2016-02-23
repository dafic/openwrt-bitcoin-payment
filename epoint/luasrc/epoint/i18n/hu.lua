module("epoint.i18n.hu", package.seeall)

selfname = "Magyar"

local translations = {
    ["Billing information"] = "Számlázási adatok",
    ["Save"] = "Mentés",
    ["Clear"] = "Törlés",
    ["Important: cookies must be enabled for billing to work."] =
         "<strong>Fontos:</strong> a cookie-kat be kell kapcsolni a számlázáshoz.",
    ["Error: cookies are disabled in your browser."] = 
         "Hiba: a cookie-k ki vannak kapcsolva a böngészőben.",
    ["Name"] = "Név",
    ["Address"] = "Cím",
    ["%d day"] = "%d nap",
    ["%d hour"] = "%d óra",
    ["%d minute"] = "%d perc",
    ["Unlimited access"] = "Korlátlan",
    ["No access"] = "Elfogyott",
    -- splash form
    ["Welcome!"] = "Üdvözöljük!",
    ["Payment"] = "Fizetés",
    ["Enter ePoint rand:"] = "ePoint rand:",
    ["After paying, it is safe to close the browser window."] =
        "Fizetés után a böngészőablak becsukható.",
    ["Rates"] = "Árak",
    ["Per-minute"] = "Percdíj",
    ["Hourly"] = "Óradíj",
    ["Daily"] = "Napidíj",
    ["Monthly"] = "Havidíj",
    ["One hour"] = "Egy óra",
    ["One day"] = "Egy nap",
    ["One month"] = "Egy hónap",
    ["Issuer of accepted RANDs:"] = "Az elfogadott randok kibocsátója:",
    ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
        "Amennyiben ÁFÁs számlára van szüksége, <a href='%s'>ide kattintva</a> adja meg számlázási adatait.",
    ["Invoice"] = "ÁFÁs számla",
    ["Buyer:"] = "Vevő:",
    ["Billing address:"] = "Számlázási cím:",
    ["Click here to modify."] = "Változtatáshoz kattintson ide.",
    ["Customer support line:"] = "Ügyfélszolgálat telefonszáma:",
    -- error messages
    ["Payment timestamp differs too much from current time. Please, check router's clock."] =
        "A fizetés időbélyege jelentősen eltér a pontos időtől. Kérem ellenőrizze a rendszeridőt.",
    ["Invalid payment"] = "Érvénytelen utalvány",
    ["Internal error"] = "Program hiba",
    ["Network error"] = "Hálózati hiba",
    ["Missing parameters"] = "Paraméterek hiányoznak",
    ["Invalid parameters"] = "Érvénytelen paraméterek",
    ["Invalid RAND"] = "Érvénytelen RAND",
    ["Insufficient payment"] = "Fizetett összeg nem elég",
    ["Submitted RAND had bad format."] = "A megadott RAND formátuma rossz.",
    ["Please submit the form properly."] = "Helyesen töltse ki az ürlapot.",
    ["Could not determine network address"] = "A hálozati címet nem sikerült meghatározni",
    ["Payment below minimum"] = "A befizetett összeg kevesebb a minimálisnál",
    ["You are whitelisted"] = "Ön fehérlistán van",
    ["Timeout"] = "Az hozzáférés ideje lejárt",
    ["Try to pay again"] = "Próbálja meg újra",
    ["Check status"] = "Állapot ellenörzése",
    -- status page
    ["Thank you!"] = "Köszönöm!",
    ["Status"] = "Állapot",
    ["You can log out here"] = "Használat befejezése",
    ["You can now visit %s."] = "Megnézheti a %s oldalt.",
    ["Remaining time:"] = "Hátralévő idő:",
    ["You can safely close this window."] =
        "Ezt az oldalt nyugodtan becsukhatja.",
    ["Buy more time"] = "További idő vásárlása",
    ["You will be redirected to %s in a few seconds."] =
        "Néhány másodperc múlva itt folytathatja: %s."

}

function translate(msgid, ...)
    return translations[msgid] or msgid
end
