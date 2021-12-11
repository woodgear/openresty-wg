local _M = {}

function _M.trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
function _M.assert_eq(left, right,msg)
    if not (left == right) then
        ngx.log(ngx.ERR,
                tostring(left) .. " ? " .. tostring(right) .. "  " ..
                    tostring(left == right) .. " msg "..tostring(msg).."\n")
        ngx.exit(ngx.ERR)
    end
end

function _M.assert_contains(left, right)
    if left:find(right) then
        return true
    end
    ngx.log(ngx.ERR,"could not find "..right.." in "..left)
    ngx.exit(ngx.ERR)
end

function _M.md5(text)
    local resty_md5 = require "resty.md5"
    local str = require "resty.string"

    local md5 = resty_md5:new()
    if not md5 then
        ngx.say("failed to create md5 object")
        return
    end
    local ok = md5:update(text)
    if not ok then
        ngx.say("failed to add data")
        return
    end

    local digest = md5:final()
    return str.to_hex(digest)
end


function _M.get_domain_a_cert(msg)  
    local cert= [[
-----BEGIN CERTIFICATE-----
MIIFGTCCAwGgAwIBAgIURSC9Gf8dysFMGm9pzNgfcFKvszUwDQYJKoZIhvcNAQEL
BQAwEDEOMAwGA1UEAwwFYS5jb20wHhcNMjExMTMwMDczNzQwWhcNMzExMTI4MDcz
NzQwWjAQMQ4wDAYDVQQDDAVhLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
AgoCggIBAKvydLtilKD9ypJ881oKOK0lP71lpONW8NRqiajH56xLhEPogXgmd8vR
uAlgADH0AePsDRCdhdOmodRT9rqxzjPWyUyNVVQUvldL4GLLfMhw+gx5LKAVpVYN
LwXwaKj2yMbV3EqWlwTryTdnTa/Lp7JGHrFWdRQ5mzvd19TEmueZq2iGVrUALwG/
aBGpfTee+r/kqAByb8Ce2hRZ4Mdq0foAZkUYl4AAYLBt4BE9jCItNKEhd4nqYof7
cWwy64ahwuBY3mveW4mq+GpdRWW/3ncUTzPxSFz3tqyc6JiEmtrRCcptKR+kndwO
6Mf3euYT7kcVWaKBRbxWDpEVAz15TZ1wugEVpWBlFuo20HBYL/Oiu6ZFLmVtl6XE
//4DeUTqmUOX5Ks4reALsC4JtphlgOAEe0XN4/YtestpkLqqYNpCXU+YkQgTgOYs
/FWN1OQ8ybVTG+5Hej4tHcEvcR7polPYPhEYY2eHpZ8Rvejt6UgzzaWQeRx0DZKr
wqgZqoRmV07KLf17nyVsgmROJ6SQMGnj3PZ184GR+nkZR4WYgNmElT0RfoplaULT
25VP3ea0B3cWDfBojGK3HizK1u0eHOL86FJv1EDfdMB+UfekZwQPvg7FMNMptJYT
3yb+qfWnjUAmg4StMse6qyHyoU1PDcoHOzB6bcEYFNhhoM2AWK6DAgMBAAGjazBp
MB0GA1UdDgQWBBSIKm9hBEcu/7m+LGgXuPrM7r0F2jAfBgNVHSMEGDAWgBSIKm9h
BEcu/7m+LGgXuPrM7r0F2jAPBgNVHRMBAf8EBTADAQH/MBYGA1UdEQQPMA2CBWEu
Y29thwQKxwARMA0GCSqGSIb3DQEBCwUAA4ICAQBd102imkQm0fiTUjjy4yXgwu2V
tqmdCuUkD3tjKgptD2+Cm6vkL+RKDCTZrnVaz2ouWJhwRucFV+40tCnfT/XMbXAD
+BcNmEr7aUHbSfo0pKTUVx+gaKhlZn/vLa5Cy9IflyLVLVvOj87iPNpuKiGPfHzw
5XOfnUrEJrlCu/kme1zjEb1Ffilp2eTKF55vDn4Nn2HfyoCGSXoZ6ovg9aRR0D1g
wjRyASW+zt2J5aJMEdgNAQGMuXcAXGfP5EpMX9O8A/AMFomzZ3mZNkxlZmuoa+eB
ZJRq7WrB+yZrRbQz14dRxzHLYd7J7dZCEV/+GclL9PpyNKlUm1WANOaDAD8O91TR
Orbi63QsCJOYjmEzBUMFZR6SA0NE3o9R+w7k4NwfMJvwWY1BCnqG0VrsGN98InOm
9NIO9nwcPvthsg1CmmlAzfLkyI2CeB1pp/2joljQz3CTey7lzKQkZn71y+WLB7LS
ozTeY61mPBWYWLGGrm4xuyKxYOpF4RUoZ7Aa/xToVMq18yicsS6aMUxvis6c30Ak
+vVoccIKvwvKWexeupVFPrIhGeMsf1TkIzNXgmMikEZU5FfO7QOXxmYwj1KFPr1d
HE9x8OkhxTqrpkR10c7NJcSWvMmnsWuMb7qMtfZyGX05SZ5ClLlZL1urlAp9DM8z
Mc1vg+1kIsWtdGv2TA==
-----END CERTIFICATE-----
        

    ]]
    local key = [[
-----BEGIN PRIVATE KEY-----
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
CwpqVFjp+yL15yLK1SEmCnczrK8g+FGI
-----END PRIVATE KEY-----
    ]]
    return cert, key
end

function _M.get_domain_b_cert(msg) ngx.log(ngx.INFO, msg) 
    local cert= [[
-----BEGIN CERTIFICATE-----
MIIFGTCCAwGgAwIBAgIUBRvJ/PQABXRJh5pPEcA/SiQREtUwDQYJKoZIhvcNAQEL
BQAwEDEOMAwGA1UEAwwFYi5jb20wHhcNMjExMTMwMDYxNDU3WhcNMzExMTI4MDYx
NDU3WjAQMQ4wDAYDVQQDDAViLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
AgoCggIBALqIMdOlUV7fOfv53v/4meevtGs4x2bokJ/JR5WKhNs1/a9nTcO0OPtg
CLvR0zrwD4UK1SOEzOWpb9p7ZX9PGHTvTQ8pXKdph1yiIsgb8WrLcUI0aItqBK3h
MIqe49Q4QJvl79XIxcv559ZLvzoxN532TRq6sYD8F20vWHXPB3tJoCGSImBxE/NJ
BGbGi72MqicYetI/b/aJsrbpT+4hssDZGzn1muA2opgbzNXYpt743FG1G5mBZ4nI
kVH4ZzpuWUeG0Uz0yYVhMFzROIU8SKrLOYWvRJgkDxxsNa3Ui1P1cVuhpzbqxoBb
XiY75H8oajwZ4okNM4CW3ww8GhL6zWryu2WNLy1pW0LCFoAZz8rCGtXZ3E7sH5C0
E/biLF1xBTsuIvHwbKGTm7tO4OQYvRfd6tubDROvP2JuBOfTVbkjYQnUbo91Tak1
zaGK1aqufxxDES/tR+cHhmhq7mOBep1/u6q10/XC1s45WwbYjxmOQ7xPXxjnmozl
1TVIHU4e37Zrb3e28oWg9aFjYempAZAH8NV//4SNafA8OE0S5dLRF2zkUUtl+Ej8
zJ3hL6TwWBiOTioAGK0LX2ge5K9Uj7ztzH0qnNT5DuENGSFBH3/yluvp+4/e6vJv
Vj5LK1jYMUw+ge0t25k+Ho/6Sac3/wlr1tgg+TlP3PoiPYaOLywzAgMBAAGjazBp
MB0GA1UdDgQWBBTnjK4AgfzRKcwz4Ft4hcF9/7pYvzAfBgNVHSMEGDAWgBTnjK4A
gfzRKcwz4Ft4hcF9/7pYvzAPBgNVHRMBAf8EBTADAQH/MBYGA1UdEQQPMA2CBWIu
Y29thwQKxwARMA0GCSqGSIb3DQEBCwUAA4ICAQBNTbWBwG1CuOPAFagOdZfq2khZ
vBH8f8kmXEFX8dkDCjuy8+5FPOUHee+tMcXfuOn3zKCpFQvypry4E2OPGdkewswv
KGzlceOOPqMm9EOYrggawmbh57UQ2yr9t/r08JsG4spSzjJoe79mavwI5vVRtWdN
XNdej+lvYHfWJktAGYnthQndAfAGYRYjmFiA2btuWPuxOFnvEIIYwRs+BDHtXkMv
d48T/+CPmQ5rjcO5trF7/GfovEGPevPxYLZnTcbc/7BsNv6tqFPnmR/sMezGjCCc
7tiISY44ske1NxwfUmnV3lfB6n+L5Dwim3oOt5ZN+rnwIiuXRBGVoK+u6gBBy9MA
/K1L6ZjbU5F3/IBCsAwzHIGAmyf2JulilkBDdhxL8T7PeQtLzRLUCtSHjbTChb/N
0RsD8QJh6B1pYuU7f4t+TlD7bxnRND9NvT27913RiwONeZ+qdqUnjXSYwXsSSBYH
YPzfGt9WWhMQxEhXPK7qif/saw249gM38YCeKV7PYmzya+tvGzgM67zEqbQ4lQU6
l3QIUhg3YQmYkXs4eJ8epFopIvOjFRHB1QQkbkF9ld3XvC9n2a7AFkO6yfZkWjrT
naBA8Z1QAgwvT7t8J6de/hWBelZMRuPuxbI+M3fKzKq4GCVVaPM/ZYmJfQsVYOR6
QOQ5Wxvz7Mek+ifQ8g==
-----END CERTIFICATE-----
    ]]
    local key = [[
-----BEGIN PRIVATE KEY-----
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
6snOygikaveVEJiD8nRJZ3M8UqnW
-----END PRIVATE KEY-----
    ]]
    return cert,key
end

function _M.info(msg) ngx.log(ngx.INFO, msg) end


function _M.set_cert_and_key(cert,key) 
    local ssl = require "ngx.ssl"
    local ok, err = ssl.clear_certs()
    ngx.log(ngx.INFO, "clear_certs success")
    if not ok then
        ngx.log(ngx.ERR, "clear cert fail: ", err)
        return ngx.exit(ngx.ERROR)
    end

    local der_cert_chain, err = ssl.cert_pem_to_der(cert)
    if not der_cert_chain then
        ngx.log(ngx.ERR, "pem to der cert fail: ", err)
        return ngx.exit(ngx.ERROR)
    end
    ngx.log(ngx.INFO, "pem to der cert success")


    local ok, err = ssl.set_der_cert(der_cert_chain)
    if not ok then
        ngx.log(ngx.ERR, "failed to set DER cert: ", err)
        return ngx.exit(ngx.ERROR)
    end
    ngx.log(ngx.INFO, "set der cert success")

    local der_pkey, err = ssl.priv_key_pem_to_der(key)
    if not der_pkey then
        ngx.log(ngx.ERR, "pem to der key fail ", err)
        return ngx.exit(ngx.ERROR)
    end
    ngx.log(ngx.INFO, "pem to der key success")

    local ok, err = ssl.set_der_priv_key(der_pkey)
    if not ok then
        ngx.log(ngx.ERR, "failed to set DER private key: ", err)
        return ngx.exit(ngx.ERROR)
    end
end



return _M