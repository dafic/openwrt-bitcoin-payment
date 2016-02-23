module("epoint.i18n.fr", package.seeall)

selfname = "Français"

-- form1 - singulier
-- form2 - pluriel
local function plural(form1, form2)
    return function(n)
        if n < 2 then
            return form1
        else
            return form2
        end
    end
end

local translations = {
    ["Billing information"] = "Information de facturation",
    ["Save"] = "Sauvegarder",
    ["Clear"] = "Effacer", -- effacer is erase. Reset a whole form? "Remettre à zéro"
    ["Name"] = "Nom",
    ["Address"] = "Adresse",
    ["Important: cookies must be enabled for billing to work."] =
        "Nota Bene: votre navigateur doit accepter les cookies pour que la facturation fonctionne",
    ["Error: cookies are disabled in your browser."] =
        "Erreur: votre navigateur refuse les cookies. Veuillez les activer.",
    ["%d day"] = plural("%d jour", "%d jours"),
    ["%d hour"] = plural("%d heure", "%d heures"), -- note: pluralize for durations, not for time of day.
    ["%d minute"] = plural("%d minute", "%d minutes"),
    ["Unlimited access"] = "Accès illimité",
    ["No access"] = "Accès refusé", -- For "Access rejected". Or maybe "Accès restreint"?
    -- splash form
    ["Welcome!"] = "Bienvenue!",
    ["Payment"] = "Paiement",
    ["Enter ePoint rand:"] = "Saisissez votre rand ePoint: ", -- who's ayn rand? I translated as "number". Why lower case here, upper case there? litteral translation would be "aléa", short for "aléatoire" (as in "nombre aléatoire", random number), but "les aléas de la vie" are the random mostly *bad* events of your life, and/or has a bad connotation of loss of control. Not strong a connotation, and the translation wouldn't work, but why take the marketing risk? Hence, semantic depreciation of any word with a bad connotation, and semantic inflation of euphemisms that replace them. Maybe aléanum?
    ["After paying, it is safe to close the browser window."] =
        "Après paiement, vous pouvez fermer la fenêtre de votre navigateur en toute sécurité",
    ["Rates"] = "Taux", -- Fits most contexts; dunno about yours.
    ["Per-minute"] = "la minute",
    ["Hourly"] = "l'heure",
    ["Daily"] = "la journée",
    ["Monthly"] = "le mois",
    ["Issuer of accepted RANDs:"] = "Émetteur de rands acceptés:", -- d'aléanums:
    ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
        "Si vous désirez une facture imprimée, veuillez cliquer <a href='%s'>ici</a> pour saisir vos informations de facturation.",
        -- "un devis" instead of "une facture" if it's an offer rather than a done deal. "facture" implies that the offer was accepted.
    ["Invoice"] = "Devis",
    ["Buyer:"] = "Acheteur:",
    ["Billing address:"] = "Adresse de facturation",
    ["Click here to modify."] = "Cliquer ici pour modifier",
    ["Customer support line:"] = "Service client:",
    -- error messages
    ["Payment timestamp differs too much from current time. Please, check router's clock."] =
        "Le décalage entre l'heure associée au paiement et l'heure actuelle est excessif. Veuillez vérifier l'horloge de votre routeur.",
    ["Invalid payment"] = "Paiement non valide",
    ["Payment below minimum"] = "Paiement inférieur au minimum requis",
    ["You are whitelisted"] = "Vous êtes sur la liste blanche",
    ["Timeout"] = "Dépassement de temps d'attente",
    ["Try to pay again"] = "Tenter un nouveau paiement",
    -- splash-redir
    ["Thank you!"] = "Merci!",
    ["Status"] = "État",
    ["You can log out here"] = "Déconnexion",
    ["You can now visit %s."] = "Vous pouvez maintenant visiter %s",
    ["Remaining time:"] = "Temps restant:",
    ["You can safely close this window."] =
        "Vous pouvez fermer cette fenêtre.",
    ["Buy more time"] = "Acheter davantage de temps",
    ["You will be redirected to %s in a few seconds."] =
        "Votre navigateur sera redirigé vers %s dans quelques secondes."
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
