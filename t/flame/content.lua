local spend = function(f)
    ngx.update_time()
    local s = ngx.now()
    f()
    ngx.update_time()
    local e = ngx.now()
    return e - s
end
local other1 = function(a)
    local resty_md5 = require "resty.md5"
    local str = require "resty.string"
    for i = 0, 100, 1 do
        local md5 = resty_md5:new()
        local digest = md5:final()
    end
end
local slow = function()
    for i = 0, 100, 1 do
        other1()
    end
end
ngx.say(spend(slow))
