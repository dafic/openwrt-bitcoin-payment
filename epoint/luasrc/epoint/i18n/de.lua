module("epoint.i18n.de", package.seeall)

selfname = "Deutsch"

-- form1 - Singular (z.B. 1 Minute)
-- form2 - Plural (z.B. 2 Minuten)
local function plural(form1, form2)
   return function(n)
       if n == 1 then
           return form1
       else
           return form2
       end
   end
end

local translations = {
   ["Billing information"] = "Rechnungsinformationen",
   ["Save"] = "Speichern",
   ["Clear"] = "Zurücksetzen",
   ["Name"] = "Name",
   ["Address"] = "Adresse",
   ["Important: cookies must be enabled for billing to work."] =
       "<strong>Wichtig:</strong> Zur korrekten Rechnungserstellung müssen Cookies aktiviert sein.",
   ["Error: cookies are disabled in your browser."] =
       "<strong>Fehler:</strong> Cookies scheinen in Ihrem Browser nicht aktiviert zu sein.",
   ["%d day"] = plural("%d Tag", "%d Tage"),
   ["%d hour"] = plural("%d Stunde", "%d Stunden"),
   ["%d minute"] = plural("%d Minute", "%d Minuten"),
   ["Unlimited access"] = "unbegrenzter Zugriff",
   ["No access"] = "kein Zugriff",
   -- splash form
   ["Welcome!"] = "Willkommen!",
   ["Payment"] = "Freischalten",
   ["Enter ePoint rand:"] = "Bitte geben Sie Ihren ePoint Code ein:",
   ["After paying, it is safe to close the browser window."] =
       "Nach erfolgreicher Bezahlung können Sie gefahrlos das Browserfenster schließen.",
   ["Rates"] = "Preise",
   ["Per-minute"] = "pro Minute",
   ["Hourly"] = "pro Stunde",
   ["Daily"] = "pro Tag",
   ["Monthly"] = "pro Monat",
   ["Issuer of accepted RANDs:"] = "Herausgeber der akzeptierten ePoint Codes:",
   ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
      "Wenn Sie eine gedruckte Rechnung benötigen, klicken Sie bitte <a href='%s'>hier</a> um die notwendigen Rechnungsinformationen einzugeben.",
   ["Invoice"] = "Rechnung",
   ["Buyer:"] = "Käufer:",
   ["Billing address:"] = "Rechnungsadresse:",
   ["Click here to modify."] = "Hier klicken, um die Rechnungsinformationen zu ändern.",
   ["Customer support line:"] = "Hotline:",
   -- error messages
   ["Payment timestamp differs too much from current time. Please, check router's clock."] =
       "Der Zeitstempel der Zahlung weicht zu sehr von der aktuellen Uhrzeit ab, bitte kontrollieren Sie die Uhrzeiteinstellung des Routers.",
   ["Invalid payment"] = "Ungültige Zahlung",
   ["Payment below minimum"] = "Die Zahlung liegt unter dem Mindestbetrag",
   ["You are whitelisted"] = "Sie stehen auf der White-List",
   ["Timeout"] = "Zeitüberschreitung",
   ["Try to pay again"] = "Bitte versuchen Sie erneut zu bezahlen",
   -- splash-redir
   ["Thank you!"] = "Vielen Dank!",
   ["Status"] = "Status",
   ["You can log out here"] = "Ausloggen",
   ["You can now visit %s."] = "Sie können jetzt %s besuchen.",
   ["Remaining time:"] = "Verbleibende Zeit:",
   ["You can safely close this window."] =
       "Sie können gefahrlos das Fenster schließen.",
   ["Buy more time"] = "Weitere Zeit freischalten",
   ["You will be redirected to %s in a few seconds."] =
       "Sie werden in wenigen Sekunden auf %s weitergeleitet."
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
