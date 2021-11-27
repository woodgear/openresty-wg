use lib 'lib';
use Test::Nginx::Socket 'no_plan';

repeat_each(2);

#$Test::Nginx::LWP::LogLevel = 'debug';

run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location /echo {
        echo hello;
    }
--- request
    GET /echo
--- response_body
hello
