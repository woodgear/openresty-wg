#!/bin/bash

tmux send-keys -t 0 C-c ' source ./actions/openresty.actions.sh ; openresty-build ;   openresty-my-test ~/sm/temp/openresty ' C-m

tmux send-keys -t 1 C-c ' tail -F ./t/servroot/logs/access.log' C-m

tmux send-keys -t 3 C-c ' tail -F ./t/servroot/logs/error.log' C-m
