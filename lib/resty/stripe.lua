--
-- Generated from stripe.lt
--
local json = require("cjson")
local Host = "api.stripe.com"
local Uri = "https://" .. Host .. "/v1/"
local rand = function(min, max)
    return min + 0.5 + math.random() * (max - min)
end
local round = function(num, decimals)
    local power = 10 ^ decimals
    return math.floor(num * power) / power
end
local explode
explode = function(obj)
    local out = {}
    if obj then
        for k, v in pairs(obj) do
            local n = tonumber(k)
            if n then
                n = n - 1
            else
                n = k
            end
            local key = "[" .. n .. "]"
            if "table" == type(v) then
                for x, y in pairs(explode(v)) do
                    out[key .. x] = y
                end
            else
                out[key] = v
            end
        end
    end
    return out
end
local merge = function(params, opt)
    if opt then
        for key, val in pairs(opt) do
            if "table" == type(val) then
                for k, v in pairs(explode(val)) do
                    params[key .. k] = v
                end
            else
                params[key] = val
            end
        end
    end
    return params
end
local escape = function(txt)
    if "string" == type(txt) then
        local s = string.gsub(txt, "([^0-9a-zA-Z !'()*._~-])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        return string.gsub(s, " ", "+")
    end
    return tostring(txt)
end
local encode_args = function(t)
    if t and next(t) then
        local acc, a = {}, 1
        for key, val in pairs(t) do
            if "table" == type(val) then
                for _, v in ipairs(val) do
                    acc[a] = key .. "=" .. escape(v)
                end
            else
                acc[a] = key .. "=" .. escape(val)
            end
            a = a + 1
        end
        return table.concat(acc, "&")
    end
    return ""
end
local fix_null
fix_null = function(tb)
    for k, v in pairs(tb) do
        if v == ngx.null then
            tb[k] = nil
        elseif "table" == type(v) then
            fix_null(v)
        end
    end
end
return function(client, api_key)
    local request = function(method, path, params, header)
        local url = Uri .. path
        local body
        if params then
            params = merge({}, params)
            body = encode_args(params)
        end
        local headers = {Host = Host, Authorization = "Basic " .. ngx.encode_base64(api_key), Accept = "application/json", ["Content-Type"] = "application/x-www-form-urlencoded"}
        if header then
            for k, v in pairs(header) do
                headers[k] = v
            end
        end
        local opt = {method = method, headers = headers, ssl_verify = false}
        if body then
            if method == "GET" then
                opt.query = body
            else
                body = string.gsub(body, "%%5B", "["):gsub("%%5D", "]")
                opt.body = body
                headers["Content-Length"] = #body
            end
        end
        local res, err
        local retries = headers["Idempotency-Key"] and 3 or 1
        for i = 1, retries do
            res, err = client:request_uri(url, opt)
            if res then
                local retry = res.headers["Stripe-Should-Retry"]
                if not retry or retry == "false" then
                    local data = json.decode(res.body)
                    fix_null(data)
                    if res.status < 200 or res.status > 299 then
                        local msg = data and data.error and data.error.message
                        ngx.log(ngx.ERR, res.status, " ", msg or "stripe error without message")
                        if msg then
                            local shorten = string.match(data.error.message, "^(.+)%.%s%u.+$")
                            if shorten then
                                data.error.message = shorten
                            end
                        end
                    end
                    return res.status, res.headers, data
                end
            end
            if err then
                ngx.log(ngx.ERR, "HTTP request error: ", err)
            end
            ngx.sleep(round(rand(3, 8), 3))
        end
        return ngx.HTTP_SERVICE_UNAVAILABLE, err
    end
    local list = function(class, params)
        return request("GET", class, params)
    end
    local get = function(class, id, params)
        return request("GET", class .. "/" .. id, params)
    end
    local create = function(class, params, headers)
        return request("POST", class, params, headers)
    end
    local post = function(class, id, params, headers)
        return request("POST", class .. "/" .. id, params, headers)
    end
    local delete = function(class, id, params)
        return request("DELETE", class .. "/" .. id, params)
    end
    local K = {}
    local Balance = "balance"
    K.balance = {get = function(opt)
        return list(Balance, opt)
    end}
    local BalanceTransactions = "balance_transactions"
    K.balance_transactions = {get = function(id, opt)
        return get(BalanceTransactions, id, opt)
    end, list = function(opt)
        return list(BalanceTransactions, opt)
    end}
    K.account = {}
    local Charges = "charges"
    K.charge = {get = function(id, opt)
        return get(Charges, id, opt)
    end, create = function(...)
        return create(Charges, ...)
    end, update = function(id, ...)
        return post(Charges, id, ...)
    end, capture = function(id, ...)
        return post(Charges, id .. "/capture", ...)
    end, list = function(opt)
        return list(Charges, opt)
    end}
    local Customers = "customers"
    K.customers = {get = function(id, opt)
        return get(Customers, id, opt)
    end, create = function(...)
        return create(Customers, ...)
    end, update = function(id, ...)
        return post(Customers, id, ...)
    end, delete = function(id)
        return delete(Customers, id)
    end, list = function(opt)
        return list(Customers, opt)
    end}
    local Invoices = "invoices"
    K.invoices = {
        get = function(id, opt)
            return get(Invoices, id, opt)
        end
        , upcoming = function(opt)
            return get(Invoices, "upcoming", opt)
        end
        , upcominglines = function(opt)
            return get(Invoices, "upcoming/lines", opt)
        end
        , lines = function(id, opt)
            return get(Invoices, id .. "/lines", opt)
        end
        , create = function(...)
            return create(Invoices, ...)
        end
        , update = function(id, ...)
            return post(Invoices, id, ...)
        end
        , finalize = function(id, ...)
            return post(Invoices, id .. "/finalize", ...)
        end
        , pay = function(id, ...)
            return post(Invoices, id .. "/pay", ...)
        end
        , send = function(id, ...)
            return post(Invoices, id .. "/send", ...)
        end
        , void = function(id, ...)
            return post(Invoices, id .. "/send", ...)
        end
        , bad = function(id, ...)
            return post(Invoices, id .. "/mark_uncollectible", ...)
        end
        , delete = function(id)
            return delete(Invoices, id)
        end
        , list = function(opt)
            return list(Invoices, opt)
        end
    }
    local InvoiceItems = "invoiceitems"
    K.invoice_items = {create = function(...)
        return create(InvoiceItems, ...)
    end, get = function(id)
        return get(InvoiceItems, id)
    end, update = function(id, ...)
        return post(InvoiceItems, id, ...)
    end, delete = function(id)
        return delete(InvoiceItems, id)
    end, list = function(opt)
        return list(InvoiceItems, opt)
    end}
    local PaymentIntents = "payment_intents"
    K.payment_intents = {
        create = function(...)
            return create(PaymentIntents, ...)
        end
        , get = function(id, opt)
            return get(PaymentIntents, id, opt)
        end
        , update = function(id, ...)
            return post(PaymentIntents, id, ...)
        end
        , confirm = function(id, ...)
            return post(PaymentIntents, id .. "/confirm", ...)
        end
        , capture = function(id, ...)
            return post(PaymentIntents, id .. "/capture", ...)
        end
        , cancel = function(id, ...)
            return post(PaymentIntents, id .. "/cancel", ...)
        end
        , list = function(opt)
            return list(PaymentIntents, opt)
        end
    }
    local PaymentMethods = "payment_methods"
    K.payment_methods = {
        get = function(id, opt)
            return get(PaymentMethods, id, opt)
        end
        , create = function(...)
            return create(PaymentMethods, ...)
        end
        , update = function(id, ...)
            return post(PaymentMethods, id, ...)
        end
        , confirm = function(id, ...)
            return post(PaymentMethods, id .. "/confirm", ...)
        end
        , cancel = function(id, ...)
            return post(PaymentMethods, id .. "/cancel", ...)
        end
        , attach = function(id, ...)
            return post(PaymentMethods, id .. "/attach", ...)
        end
        , detach = function(id, ...)
            return post(PaymentMethods, id .. "/detach", ...)
        end
        , list = function(opt)
            return list(PaymentMethods, opt)
        end
    }
    local PromotionCodes = "promotion_codes"
    K.promotion_codes = {get = function(id)
        return get(PromotionCodes, id)
    end, create = function(...)
        return create(PromotionCodes, ...)
    end, update = function(id, ...)
        return post(PromotionCodes, id, ...)
    end, list = function(opt)
        return list(PromotionCodes, opt)
    end}
    local SetupIntents = "setup_intents"
    K.setup_intents = {
        get = function(id, opt)
            return get(SetupIntents, id, opt)
        end
        , create = function(...)
            return create(SetupIntents, ...)
        end
        , update = function(id, ...)
            return post(SetupIntents, id, ...)
        end
        , confirm = function(id, ...)
            return post(SetupIntents, id .. "/confirm", ...)
        end
        , cancel = function(id, ...)
            return post(SetupIntents, id .. "/cancel", ...)
        end
        , list = function(opt)
            return list(SetupIntents, opt)
        end
    }
    local Subscriptions = "subscriptions"
    K.subscriptions = {get = function(id, opt)
        return get(Subscriptions, id, opt)
    end, create = function(...)
        return create(Subscriptions, ...)
    end, update = function(id, ...)
        return post(Subscriptions, id, ...)
    end, delete = function(id, opt)
        return delete(Subscriptions, id, opt)
    end, list = function(opt)
        return list(Subscriptions, opt)
    end}
    local SubscriptionItems = "subscription_items"
    K.subscription_items = {
        create = function(...)
            return create(SubscriptionItems, ...)
        end
        , get = function(id)
            return get(SubscriptionItems, id)
        end
        , update = function(id, ...)
            return post(SubscriptionItems, id, ...)
        end
        , delete = function(id)
            return delete(SubscriptionItems, id)
        end
        , list = function(opt)
            return list(SubscriptionItems, opt)
        end
        , usage = function(id, ...)
            return post(SubscriptionItems, id .. "/usage_records", ...)
        end
        , usages = function(id, opt)
            return get(SubscriptionItems, id .. "/usage_record_summaries", opt)
        end
    }
    local Checkouts = "checkout/sessions"
    K.checkouts = {create = function(...)
        return create(Checkouts, ...)
    end}
    return K
end
