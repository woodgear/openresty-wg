function openresty-isvalid-nginx-config {
    # -c $PWD/t/nginx.sample.conf
    # -p  $PWD/t
    # -e $PWD/t/servroot/logs/error.log
    local c=""
    local p=""
    local e=""
    nginx -t -c $c -p $p -e $e
}

function openresty-my-test-all {
    openresty-set-path ~/sm/temp/openresty-wg
}    

function openresty-my-test {
    openresty-set-path ~/sm/temp/openresty-wg
    prove -I ./vendor/test-nginx/lib -r ./t/mine.t
    echo $PWD
    nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf
    openresty-perf-flamegraph

    pkill nginx
}

function openresty-perf-flamegraph {
    # prove -I ./vendor/test-nginx/lib -r ./t/mine.t; nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf; . ./actions/openresty.actions.sh; openresty-flamegraph
    sudo perf record -p "$1" -F 99 -a -g &
    local pid=$!
    local n=10
    echo "perf run in bg $pid wait $n s"
    echo $PWD
    sleep $n
    sudo kill -INT $pid
    sleep 1
    sudo chmod a+rw ./perf.data
    perf script >perf.bt
    /home/cong/sm/lab/FlameGraph/stackcollapse-perf.pl perf.bt >perf.cbt
    /home/cong/sm/lab/FlameGraph/flamegraph.pl perf.cbt >perf.svg
    firefox ./perf.svg
}

function openresty-profile-bcc-flamegraph {
    local n=10
    echo "will run  bcc profile $pid wait $n s"
    sudo PROBE_LIMIT=100000 ~/sm/lab/bcc/tools/profile.py --stack-storage-size 204800 -af -p $(pgrep nginx) 10 >profile.stacks
    /home/cong/sm/lab/FlameGraph/flamegraph.pl <./profile.stacks >./profile.stacks.svg
    firefox ./profile.stacks.svg &
}

function openresty-gdb {
    echo "you must stop bpftrace for the process first"
    local pid=$(ps -aux | grep nginx | grep 'openresty-wg' | awk '{print $2}')
    local gdbinit=$(
        cat <<EOF
    info functions eyes
EOF
    )
    echo "$gdbinit" >./gdbinit
    sudo ugdb -p $pid -x ./gdbinit
    return
}

function ngx-on-epoll-process-event {
    code=$(
        cat <<EOF
BEGIN 
{
	time("%H:%M:%S");
	printf(" start\n");
}
uprobe:./t/nginx:ngx_epoll_process_events
{
	printf(" epoll process flags %x\n",arg3);
}
END
{
	time("%H:%M:%S");
	printf(" end\n");
}
EOF
    )
    echo "$code"
    sudo bpftrace -e "$code"
}

function gdb-steal-nginx-global-variable-address {
    local name=$1
    local gdbinit=$(
        cat <<EOF
    set confirm off
    p &$name
    quit
EOF
    )
    echo "$gdbinit" >./gdbinit
    sudo gdb -q -p $(pgrep nginx) -x ./gdbinit 2>&1 | grep $name | rg -o '0x.*\s'
}

function ngx-show-global-accept {
    # https://github.com/iovisor/bpftrace/issues/75
    local address=$(gdb-steal-nginx-global-variable-address ngx_stat_accepted0)
    local code=$(
        cat <<EOF
uretprobe:./t/nginx: ngx_event_accept {\$p=$address;printf(" ngx_event_accept ret %d\n",*\$p);}
EOF
    )
    echo $code
    sudo bpftrace -e "$code"
}

function openresty-zip() {
    zip -r openresty-wg.zip  ./openresty-wg -x ./openresty-wg/target/\* ./openresty-wg/build/\*
}

function openresty-flamegraph() {
 return 
}