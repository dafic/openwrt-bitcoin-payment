module("epoint.i18n.pt", package.seeall)

-- Portuguese (Brazilian) translation by Alan Barra (2011)
selfname = "Português"

-- form1 - singular
-- form2 - plural
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
    ["Billing information"] = "Informação de faturamento",
    ["Save"] = "Salvar",
    ["Clear"] = "Retorna campo em branco",
    ["Name"] = "Nome",
    ["Address"] = "Endereço",
    ["Important: cookies must be enabled for billing to work."] =
        "Importante: o navegador deve aceitar cookies para que a fatura funcione",
    ["Error: cookies are disabled in your browser."] =
        "Erro: cookies desativado no navegador. Você deve ativá-lo.",
    ["%d day"] = plural("%d dia", "%d dias"),
    ["%d hour"] = plural("%d hora", "%d horas"), -- note: pluralize for durations, not for time of day.
    ["%d minute"] = plural("%d minuto", "%d minutos"),
    ["Unlimited access"] = "Acesso Ilimitado",
    ["No access"] = "Sem acesso", -- For "Access rejected". Or maybe "Acesso nao permitido"?
    -- splash form
    ["Welcome!"] = "Bem vindo!",
    ["Payment"] = "Pagamento",
    ["Enter ePoint rand:"] = "Código de acesso", -- is that sufficiently neutral?
    ["After paying, it is safe to close the browser window."] =
        "Após o pagamento, voce pode fechar a janela do navegador com segurança",
    ["Rates"] = "Taxa", -- Fits most contexts; dunno about yours.
    ["Per-minute"] = "por minuto",
    ["Hourly"] = "por hora",
    ["Daily"] = "por dia",
    ["Monthly"] = "por mês",
    ["Issuer of accepted RANDs:"] = "Tempo de transmissão aceito:", -- d'aléanums:
    ["If you need a printed invoice, please click <a href='%s'>here</a> to enter your billing data."] =
        "Se voce precisar da fatura impressa, por favor, clique em <a href='%s'>aqui</a> para inserir suas informações de faturamento.",
        -- "fatura" instead of "uma fatura" if it's an offer rather than a done deal. "fatura" implies that the offer was accepted.
    ["Invoice"] = "Fatura",
    ["Buyer:"] = "Comprador:",
    ["Billing address:"] = "Endereço de faturamento:",
    ["Click here to modify."] = "Clique aqui para modificar.",
    ["Customer support line:"] = "Service client:",
    -- error messages
    ["Payment timestamp differs too much from current time. Please, check router's clock."] =
        "O tempo está maior que o pagamento. Verifique o relógio do roteador.",
    ["Invalid payment"] = "Pagamento inválido",
    ["Payment below minimum"] = "Pagamento inferior ao minimo",
    ["You are whitelisted"] = "Você está na lista limpa",
    ["Timeout"] = "Tempo limite de espera",
    ["Try to pay again"] = "Tente um novo pagamento",
    -- splash-redir
    ["Thank you!"] = "Obrigado!",
    ["Status"] = "Posição",
    ["You can log out here"] = "Desconectar",
    ["You can now visit %s."] = "Agora você pode visitar %s",
    ["Remaining time:"] = "Tempo restante:",
    ["You can safely close this window."] =
        "Você pode fechar esta janela.",
    ["Buy more time"] = "Comprar mais tempo",
    ["You will be redirected to %s in a few seconds."] =
        "O seu navegador será redirecionado para %s em segundos."
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
