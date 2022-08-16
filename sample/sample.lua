--
-- Generated from sample.lt
--
local rhttp = require("resty.http")
local stripe = require("resty.stripe")
local helper = require("helper")
local cred = require("credential")
local Timeout = {Connect = 20 * 1000, Send = 20 * 1000, Read = 50 * 1000}
local http_client = function()
    local http, err = rhttp.new()
    if not http then
        return nil, err
    end
    http:set_timeouts(Timeout.Connect, Timeout.Send, Timeout.Read)
    return http
end
local test = function()
    local api = helper(stripe(http_client(), cred.Stripe.secret))
    local userid = 1
    local email = "abc@email.com"
    local phone = "655156718"
    local payment_method = "pm_card_visa"
    local status, _, cust = api.create_customer("CreateCustomerIK", userid, email, phone, payment_method)
    for k, v in pairs(cust) do
        print(k, v)
    end
end
test()
