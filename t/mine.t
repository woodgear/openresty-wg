use lib 'lib';
use Test::Nginx::Socket 'no_plan';

repeat_each(2);

#$Test::Nginx::LWP::LogLevel = 'debug';

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config 
lua_package_path '$prefix../?.lua;;' ;
--- config
    location /t {
        content_by_lua_block {
            local h = require "test-helper"
            for i=1,10000000 do 
                local md5 = h.md5("x")
                -- ngx.log(ngx.ERR,"md5 is "..md5)
            end  
            ngx.say("success")
        }
    }
--- request
    GET /t
--- response_body
success
