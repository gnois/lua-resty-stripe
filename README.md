# lua-resty-stripe
[Stripe](https://stripe.com) API for [OpenResty](https://openresty.org)


## Installation

Install dependencies:
```
opm get ledgetech/lua-resty-http    # needed to call stripe api
opm get jkeys089/lua-resty-hmac     # required by stripe_webhook.lua
```

Install:
```
opm get gnois/lua-resty-stripe
```

​
## Synopsis


```
local rhttp = require("resty.http")
local stripe = require("resty.stripe")

local ApiKey = "..."  -- your stripe api key

local api = stripe(rhttp.new(), ApiKey))

local status, headers_or_err, subs = api.subscriptions.get(subscription_id)
if status < 300 then
   -- process subscription...
end

```


## API

The list of API closely follows the REST Endpoint in [Stripe Reference](https://stripe.com/docs/api).

For creation and modification API (HTTP POST endpoints), we can supply an `Idempotency-Key` HTTP header as the last parameter which will enable 3 retries if there is error and `Stripe-Should-Retry` header is set to true, as documented in [Low level error handling](https://stripe.com/docs/error-low-level).



## Webhook

The [Stripe webhook guide](https://stripe.com/docs/webhooks) documents the steps to handle Stripe notification to your application.

Assuming we are using [Losty](https://github.com/gnois/losty), here is how we would create a webhook endpoint in our application to receive these notifications.



```
local web = require('losty.web')()   -- instantiate once
local body = require('losty.body')
local content = require('losty.content')
local wh = require('stripe_webhook')

local WebhookSecret = "whsec_nM......gu"

local w = web.route()

w.post('/stripe-webhook', content.json, function(q, r)
   local raw = body.raw(q)
   local event, err = wh.events(raw, q.headers['stripe-signature'], WebhookSecret)
   if not event then
      ngx.log(ngx.ERR, err)
      r.status = 400
   else
      local obj = event.data.object
      if 'customer.created' == event.type then
         local uid = obj.metadata['user.id']
         if uid then
            -- link user id to stripe customer id in database ...
            r.status = 200
         else
            r.status = 400
            return {fail = "invalid metadata user.id"}
         end
      end
   end
end)

```



### Adding more APIs


The list of API are not comprehensive for now, as I have only created the ones that I need.

Adding new APIs from the [Stripe Reference](https://stripe.com/docs/api) is very easy, although it is using (Luaty)[https://github.com/gnois/luaty]. Pull requests are always welcomed.

For example, looking at the reference for [SetupIntents](https://stripe.com/docs/api/setup_intents), we can see that there are `Create`, `Retrieve`, `Update`, `Confirm`, `Cancel` and `List all` operations. The Endpoints given for these operations can be directly translated into code as below:

```
var SetupIntents = "setup_intents"
K.setup_intents = {
   get = \id, opt -> return get(SetupIntents, id, opt)
   , create = \... -> return create(SetupIntents, ...)
   , update = \id, ... -> return post(SetupIntents, id, ...)
   , confirm = \id, ... -> return post(SetupIntents, id .. "/confirm", ...)
   , cancel = \id, ... -> return post(SetupIntents, id .. "/cancel", ...)
   , list = \opt -> return list(SetupIntents, opt)
}

```

There are a few patterns to note though:

- Stripe REST endpoints are using only HTTP verbs GET and POST
- HTTP GET is normally used to `list` all items or `get` one item, which should require an ID.
- HTTP POST is used to either `create` a new item or `post` changes to an item, which should require an ID, and sometimes followed by the operation name, for eg `confirm` or `cancel` as seen above. `create` and `post` functions are taking varargs because a HTTP header with an idempotency key can be passed in.





### Samples

The [sample/](https://github.com/gnois/lua-resty-stripe/tree/main/sample) folder has some real world examples. Feel free to adapt them for your own needs.

Enjoy!

