use lib 'lib';
use Test::Nginx::Socket 'no_plan';


no_shuffle();
no_root_location();
run_tests();


__DATA__

=== TEST 1: cert
--- http_config 
lua_package_path '$prefix../?.lua;;' ;
server {
    listen 2234 ssl http2; # http2 are import

    ssl_certificate     ../../resource/placeholder-cert;
    ssl_certificate_key ../../resource/placeholder.key;

    ssl_session_timeout  5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_certificate_by_lua_block {
        local h = require "test-helper"
        local b_cert,b_key = h.get_domain_b_cert()
        local a_cert,a_key = h.get_domain_a_cert()
        local cert,key = b_cert,b_key
        local cert,key = a_cert,a_key
        h.set_cert_and_key(a_cert,b_key)
    }
    location /t {
        content_by_lua_block {
            ngx.say("success")
        }
    }
}

server {
    listen 3234 ssl http2; # http2 are import

    ssl_certificate     ../../resource/placeholder-cert;
    ssl_certificate_key ../../resource/placeholder.key;

    ssl_session_timeout  5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_certificate_by_lua_block {
        local h = require "test-helper"
        local b_cert,b_key = h.get_domain_b_cert()
        h.set_cert_and_key(b_cert,b_key)
    }
    location /t {
        content_by_lua_block {
            ngx.say("success")
        }
    }
}
--- config
location /t {
    content_by_lua_block {
        local h = require "test-helper"
        local shell = require "resty.shell"

        local ok, stdout,stderr = shell.run('curl -k  https://127.0.0.1:2234/t')
        ngx.log(ngx.INFO,"ok "..tostring(ok).." stdout "..tostring(stdout).." stderr "..stderr)
        h.assert_contains(stderr,"error")



        local ok, stdout,stderr = shell.run('curl -k  https://127.0.0.1:3234/t')
        h.assert_eq(ok,true)
        h.assert_eq(h.trim(stdout),"success")

        local ok, stdout = shell.run('openssl s_client  -connect 127.0.0.1:3234 < /dev/null 2>/dev/null | openssl x509 -outform pem | certtool -i |grep DNSname')
        ngx.log(ngx.INFO,"cert info "..stdout)
        h.assert_contains(stdout,"b.com")

        ngx.say("success")
    }
}
--- request
    GET /t
--- response_body
success
