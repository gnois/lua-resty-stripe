--
-- Generated from helper.lt
--
return function(stripe)
    local next_day = function(timestamp)
        local upper = timestamp + 24 * 60 * 60
        return upper
    end
    local card_summary = function(payment_method)
        if payment_method then
            local card = payment_method.card
            if card then
                return {brand = card.brand, exp_month = card.exp_month, exp_year = card.exp_year, last4 = card.last4, fingerprint = card.fingerprint}
            end
        end
    end
    local discounts_summary = function(discs)
        local discounts
        if discs and #discs > 0 then
            discounts = {}
            for i, d in ipairs(discs) do
                local n
                if "table" == type(d.discount) then
                    n = {name = d.discount.coupon.name, duration = d.discount.coupon.duration_in_months, percent = d.discount.coupon.percent_off, start = os.date("%Y-%m-%d", d.discount.start), ["end"] = os.date("%Y-%m-%d", d.discount["end"])}
                else
                    n = {}
                end
                n.amount = d.amount
                discounts[i] = n
            end
        end
        return discounts
    end
    local intent_summary = function(i)
        if i then
            return {
                id = i.id
                , amount = i.amount
                , client_secret = i.client_secret
                , description = i.description
                , next_action = i.next_action
                , status = i.status
                , usage = i.usage
            }
        end
    end
    local lines_summary = function(inv_lines)
        local lines
        if inv_lines then
            lines = {}
            for i, l in ipairs(inv_lines.data) do
                lines[i] = {
                    amount = l.amount
                    , currency = l.currency
                    , quantity = l.quantity
                    , description = l.description
                    , priceid = l.price.id
                    , nickname = l.price.nickname
                    , unit_amount = l.price.unit_amount
                    , interval = l.price.recurring and l.price.recurring.interval
                    , usage_type = l.price.recurring and l.price.recurring.usage_type
                    , subscription_itemid = l.subscription_item
                    , period = l.period
                    , date = {start = os.date("%Y-%m-%d", l.period.start), ["end"] = os.date("%Y-%m-%d", l.period["end"])}
                }
                if l.discount_amounts then
                    lines[i].discounts = {}
                    for j, d in ipairs(l.discount_amounts) do
                        lines[i].discounts[j] = d.amount
                    end
                end
            end
        end
        return lines
    end
    local customer_summary = function(cust)
        return {
            id = cust.id
            , name = cust.name
            , balance = cust.balance
            , created = os.date("%Y-%m-%d", cust.created)
            , invoice_settings = cust.invoice_settings
            , currency = cust.currency
        }
    end
    local subscription_summary = function(sub)
        if sub then
            local s = {
                id = sub.id
                , start = os.date("%Y-%m-%d", sub.current_period_start)
                , ["end"] = os.date("%Y-%m-%d", sub.current_period_end)
                , created = os.date("%Y-%m-%d", sub.created)
                , status = sub.status
                , days_until_due = sub.days_until_due
                , cancel_at = sub.cancel_at and os.date("%Y-%m-%d", sub.cancel_at)
                , canceled_at = sub.canceled_at and os.date("%Y-%m-%d", sub.canceled_at)
                , cancel_at_period_end = sub.cancel_at_period_end
            }
            if sub.discount then
                local disc = sub.discount
                s.discount = disc.name
                s.value = disc.percent_off
            end
            if sub.default_payment_method then
                local pm = sub.default_payment_method
                local card = pm.card
                if card then
                    s.card = {brand = card.brand, exp_month = card.exp_month, exp_year = card.exp_year, last4 = card.last4, fingerprint = card.fingerprint}
                end
            end
            if sub.pending_update then
                local pu = sub.pending_update
                s.pending_update = {expires_at = os.date("%Y-%m-%d", pu.expires_at), subscription_items = {id = pu.subscription_items.id, price = pu.subscription_items.price}}
            end
            s.items = {}
            if sub.items then
                for k, itm in ipairs(sub.items.data) do
                    s.items[k] = {id = itm.id, created = os.date("%Y-%m-%d", itm.created), price = itm.price}
                    s.items[k].price.created = os.date("%Y-%m-%d", itm.price.created)
                end
            end
            return s
        end
    end
    local invoice_summary = function(inv)
        if inv then
            local i = {
                created = os.date("%Y-%m-%d", inv.created)
                , number = inv.number
                , status = inv.status
                , amount = {due = inv.amount_due, paid = inv.amount_paid, remaining = inv.amount_remaining}
                , balance = {starting = inv.starting_balance, ending = inv.ending_balance}
                , subtotal = inv.subtotal
                , total = inv.total
                , download = inv.invoice_pdf
                , pay = inv.hosted_invoice_url
                , payment_intent = intent_summary(inv.payment_intent)
            }
            if inv.due_date then
                i.due_date = os.date("%Y-%m-%d", inv.due_date)
            end
            i.lines = lines_summary(inv.lines)
            i.subscription = subscription_summary(inv.subscription)
            i.customer = customer_summary(inv.customer)
            i.discounts = discounts_summary(inv.total_discount_amounts)
            return i
        end
    end
    local update_customer_payment_method = function(customerid, paymentmethodid)
        local status, header, paymentmethod = stripe.payment_methods.attach(paymentmethodid, {customer = customerid})
        if status < 300 then
            return stripe.customers.update(customerid, {invoice_settings = {default_payment_method = paymentmethodid}})
        end
        return status, header, paymentmethod
    end
    local latest_subscription = function(customerid, expand)
        local opt = {customer = customerid, status = "all"}
        if expand then
            opt.expand = {"data.default_payment_method"}
        end
        local status, header, subs = stripe.subscriptions.list(opt)
        if status < 300 and subs.data then
            table.sort(subs.data, function(a, b)
                return a.created > b.created
            end)
            return status, header, subscription_summary(subs.data[1])
        end
        return status, header, subs
    end
    return {
        subscription_summary = subscription_summary
        , invoice_summary = invoice_summary
        , intent_summary = intent_summary
        , card_summary = card_summary
        , get_customer = function(id)
            return stripe.customers.get(id, {expand = {"subscriptions", "invoice_settings.default_payment_method"}})
        end
        , create_customer = function(idempotentkey, userid, email, phone, paymentmethodid)
            local opt = {email = email, phone = phone, metadata = {["user.id"] = userid}}
            if "string" == type(paymentmethodid) then
                opt.payment_method = paymentmethodid
                opt.invoice_settings = {default_payment_method = paymentmethodid}
            end
            return stripe.customers.create(opt, {["Idempotency-Key"] = idempotentkey})
        end
        , update_customer_payment_method = update_customer_payment_method
        , list_payment_methods = function(customerid)
            return stripe.payment_methods.list({customer = customerid, type = "card"})
        end
        , setup_intent = function(customerid)
            return stripe.setup_intents.create({customer = customerid})
        end
        , latest_subscription = latest_subscription
        , get_subscription = function(subscriptionid)
            local status, _, subs = stripe.subscriptions.get(subscriptionid)
            if status < 300 then
                return status, _, subscription_summary(subs)
            end
            return status, _, subs
        end
        , update_subscription_payment_method = function(subscriptionid, paymentmethodid)
            return stripe.subscriptions.update(subscriptionid, {default_payment_method = paymentmethodid, expand = {"default_payment_method"}})
        end
        , create_subscription = function(idempotentkey, customerid, paymentmethodid, priceids, extrapriceids, couponid, metadata, threshold_gte, trial_period)
            local opt = {customer = customerid, default_payment_method = paymentmethodid, expand = {"latest_invoice.payment_intent"}, items = {}}
            for i, p in ipairs(priceids) do
                opt.items[i] = {price = p}
            end
            if threshold_gte then
                opt.billing_thresholds = {amount_gte = threshold_gte, reset_billing_cycle_anchor = false}
            end
            if extrapriceids then
                for i, p in ipairs(extrapriceids) do
                    opt.add_invoice_items = {{price = p}}
                end
            end
            if trial_period then
                opt.trial_period_days = trial_period
            end
            opt.coupon = couponid
            opt.metadata = metadata
            return stripe.subscriptions.create(opt, {["Idempotency-Key"] = idempotentkey})
        end
        , cancel_subscription = function(subscriptionid, immediate)
            if immediate then
                return stripe.subscriptions.delete(subscriptionid, {prorate = true, invoice_now = true})
            end
            return stripe.subscriptions.update(subscriptionid, {cancel_at_period_end = true})
        end
        , uncancel_subscription = function(subscriptionid)
            return stripe.subscriptions.update(subscriptionid, {cancel_at_period_end = false})
        end
        , change_subscription = function(idempotentkey, subscriptionid, fixed, metered, priceids)
            local opt = {
                payment_behavior = "allow_incomplete"
                , proration_date = next_day(ngx.time())
                , billing_cycle_anchor = "now"
                , proration_behavior = "always_invoice"
                , expand = {"latest_invoice.payment_intent"}
                , items = {}
            }
            if fixed then
                opt.items[2] = {id = fixed.subscription_itemid, deleted = true}
            end
            if metered then
                opt.items[1] = {id = metered.subscription_itemid, deleted = true, clear_usage = true}
            end
            if priceids then
                local n = #opt.items
                for i, newid in ipairs(priceids) do
                    opt.items[i + n] = {price = newid}
                end
            end
            return stripe.subscriptions.update(subscriptionid, opt, {["Idempotency-Key"] = idempotentkey})
        end
        , get_upcoming_invoice = function(customerid, subscriptionid, fixed, metered, priceids)
            local opt
            if fixed or metered or priceids then
                opt = {subscription_proration_date = next_day(ngx.time()), subscription_billing_cycle_anchor = "now", subscription_proration_behavior = "always_invoice", expand = {"total_discount_amounts.discount"}, subscription_items = {}}
                if fixed then
                    opt.subscription_items[1] = {id = fixed.subscription_itemid, deleted = true}
                end
                if metered then
                    opt.subscription_items[2] = {id = metered.subscription_itemid, deleted = true, clear_usage = true}
                end
                if priceids then
                    local n = #opt.subscription_items
                    for i, newid in ipairs(priceids) do
                        opt.subscription_items[i + n] = {price = newid, deleted = false}
                    end
                end
            else
                opt = {expand = {"subscription", "customer.invoice_settings.default_payment_method", "total_discount_amounts.discount"}}
            end
            opt.customer = customerid
            opt.subscription = subscriptionid
            local status, _, invoice = stripe.invoices.upcoming(opt)
            if status < 300 then
                return status, _, invoice_summary(invoice)
            end
            return status, _, invoice
        end
        , list_invoices = function(customerid, limit)
            local status, _, invoices = stripe.invoices.list({customer = customerid, limit = limit or 12})
            if status < 300 then
                local invs = {}
                for k, inv in ipairs(invoices.data) do
                    invs[k] = invoice_summary(inv)
                end
                return status, _, invs
            end
            return status, _, invoices
        end
        , retry_invoice = function(invoiceid, customerid, paymentmethodid)
            local status, header, customer = update_customer_payment_method(customerid, paymentmethodid)
            if status < 300 then
                return stripe.invoices.get(invoiceid, {expand = {"payment_intent"}})
            end
            return status, header, customer
        end
        , new_promo_code = function(couponid, code, max_use, expire, first_timer)
            local opt = {coupon = couponid, code = code, max_redemptions = max_use, expires_at = expire, restrictions = {first_time_transaction = first_timer}}
            return stripe.promotion_codes.create(opt)
        end
        , create_usage = function(idempotentkey, usageitemid, quantity, action)
            assert(not action or action == "set" or action == "increment")
            return stripe.subscription_items.usage(usageitemid, {quantity = quantity, action = action or "increment", timestamp = ngx.time()}, {["Idempotency-Key"] = idempotentkey})
        end
    }
end
