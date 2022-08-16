--
-- Generated from stripe_webhook.lt
--
local hmac = require("resty.hmac")
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
                acc.timestamp = tonumber(v)
            elseif k == scheme then
                table.insert(acc.signatures, v)
            end
        end
        return acc
    end, {timestamp = -1, signatures = {}}, split(signature, ","))
end
return {event = function(body, signature, secret)
    local obj = parse_signature(signature, Scheme)
    if obj.timestamp > 0 then
        if #obj.signatures > 0 then
            local hmac256 = hmac:new(secret, hmac.ALGOS.SHA256)
            local sig = hmac256:final(obj.timestamp .. "." .. body, true)
            for _, s in ipairs(obj.signatures) do
                if s == sig then
                    local diff = ngx.time() - obj.timestamp
                    if Tolerance == 0 or diff < Tolerance then
                        return json.decode(body)
                    end
                    return nil, "timestamp outside the tolerance zone"
                end
            end
            return nil, "no signatures found matching the expected signature for payload"
        end
        return nil, "no signatures found with expected scheme"
    end
    return nil, "unable to extract timestamp and signatures from header"
end}
