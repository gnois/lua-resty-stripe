--
-- Generated from stripe_webhook.lau
--
local hmac = require("resty.hmac")
local json = require("cjson.safe")
local bit = require("bit")
local Scheme = "v1"
local Tolerance = 5 * 60
local split = function(str, pattern)
    local arr, a = {}, 1
    if pattern and #pattern > 0 then
        local pos = 1
        for st, sp in function()
            return string.find(str, pattern, pos)
        end do
            arr[a] = string.sub(str, pos, st - 1)
            a = a + 1
            pos = sp + 1
        end
        arr[a] = string.sub(str, pos)
    end
    return arr
end
local foldl = function(f, acc, list)
    local l = 0
    while l < #list do
        l = l + 1
        acc = f(acc, list[l])
    end
    return acc
end
local parse_signature = function(signature, scheme)
    return foldl(function(acc, p)
        local kv = split(p, "=")
        if #kv == 2 then
            local k, v = unpack(kv)
            if k == "t" then
                acc.timestamp = tonumber(v) or -1
            elseif k == scheme then
                table.insert(acc.signatures, v)
            end
        end
        return acc
    end, {timestamp = -1, signatures = {}}, split(signature, ","))
end
local safe_equal = function(a, b)
    if type(a) ~= "string" or type(b) ~= "string" or #a ~= #b then
        return false
    end
    local diff = 0
    for i = 1, #a do
        diff = bit.bor(diff, bit.bxor(string.byte(a, i), string.byte(b, i)))
    end
    return diff == 0
end
return {event = function(body, signature, secret)
    if type(signature) ~= "string" or signature == "" then
        return nil, "missing stripe-signature header"
    end
    local obj = parse_signature(signature, Scheme)
    if obj.timestamp > 0 then
        if #obj.signatures > 0 then
            local hmac256 = hmac:new(secret, hmac.ALGOS.SHA256)
            local sig = hmac256:final(obj.timestamp .. "." .. body, true)
            local matched = false
            for _, s in ipairs(obj.signatures) do
                if safe_equal(s, sig) then
                    matched = true
                end
            end
            if not matched then
                return nil, "no signatures found matching the expected signature for payload"
            end
            local diff = ngx.time() - obj.timestamp
            if Tolerance ~= 0 and (diff < -Tolerance or diff > Tolerance) then
                return nil, "timestamp outside the tolerance zone"
            end
            local payload, err = json.decode(body)
            if payload == nil then
                return nil, "invalid json payload: " .. tostring(err)
            end
            return payload
        end
        return nil, "no signatures found with expected scheme"
    end
    return nil, "unable to extract timestamp and signatures from header"
end}
