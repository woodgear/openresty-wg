#!/usr/bin/zsh

# tmux-send-key-to-pane run C-c ' source ./actions/openresty.actions.sh ; openresty-full-build ~/sm/temp/openresty-wg;   openresty-my-test' C-m

# tmux-send-key-to-pane access C-c ' tail -F ./t/servroot/logs/access.log' C-m

# tmux-send-key-to-pane error 1 C-c ' tail -F ./t/servroot/logs/error.log' C-m



# prove -I ./vendor/test-nginx/lib -r ./t/mine.t; nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf; . ./actions/openresty.actions.sh; openresty-flamegraph
# LD_PRELOAD=$PWD/vendor/mockeagain/mockeagain.so prove -I ./vendor/test-nginx/lib  -I ./bundle/lua-resty-core-0.1.22 -r ./bundle/lua-resty-core-0.1.22/t/balancer-timeout.t
# export PATH=~/sm/temp/openresty-wg/nginx/sbin:$PATH

# tmux-send-key-to-pane run C-c ' ' C-m
# rm -rf  ~/sm/temp/openresty-wg &&   . ./actions/openresty.actions.sh; openresty-full-build ~/sm/temp/openresty-wg
# sudo bpftrace  -v ./actions/trace.bt 
