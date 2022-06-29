#!/bin/bash

RESTY_J=10

function openresty-force-clean {
    git restore -s@ -SW  --  ./ && git clean -d -x -f
}

# apt-get install zlib1g-dev libpcre3-dev unzip  libssl-dev perl make build-essential curl libxml2-dev libxslt1-dev ca-certificates  gettext-base libgd-dev libgeoip-dev  libncurses5-dev libperl-dev libreadline-dev libxslt1-dev

# apk add git bash build-base coreutils curl gd-dev geoip-dev libxslt-dev linux-headers make perl-dev readline-dev zlib-dev gd geoip libgcc libxslt zlib -y
#    . ./actions/openresty.actions.sh 
#    mkdir -p ../rt-build 
#    OPENRESTY_SOURCE_BASE=$PWD OPENRESTY_BUILD_TRARGRT_DIR=$PWD/../rt-build openresty-full-build


function openresty-full-build {
    if [ -n "$(git status --porcelain)" ] && [ -z "$IGNORE_DITY_ROOM" ]; then 
        echo "workdir not clean use '    git restore -s@ -SW  --  ./ && git clean -d -x -f' if you want"
		return
    fi

    local START=$(($(date +%s%N)/1000000));
    SOURCE_BASE=$OPENRESTY_SOURCE_BASE
    OPENRESTY_BUILD_TRARGRT_DIR=${OPENRESTY_BUILD_TRARGRT_DIR:-$1}

    if [ -z "$OPENRESTY_SOURCE_BASE" ] ; then
        echo "OPENRESTY_SOURCE_BASE could not be empty"
        return 1
    fi

    if [ -z "$OPENRESTY_BUILD_TRARGRT_DIR" ] ; then
        echo "OPENRESTY_BUILD_TRARGRT_DIR could not be empty"
        return 1
    fi
    # clean target dir
	rm -rf "$OPENRESTY_BUILD_TRARGRT_DIR"
	mkdir -p $OPENRESTY_BUILD_TRARGRT_DIR

    echo "wg action build: source base is $SOURCE_BASE target base is $OPENRESTY_BUILD_TRARGRT_DIR"
    VENDOR=$SOURCE_BASE/vendor

    local START_OPENSSL=$(date +%s%3N)
    openresty-build-openssl
    local END_OPENSSL=$(($(date +%s%N)/1000000))

    local START_PCRE=$(($(date +%s%N)/1000000))
    openresty-build-pcre
    local END_PCRE=$(($(date +%s%N)/1000000))

    local openssl=$OPENRESTY_BUILD_TRARGRT_DIR/openssl
    local pcre=$OPENRESTY_BUILD_TRARGRT_DIR/pcre

    openresty-build-resty $openssl $pcre
    # build openssl
    
    local openssl=$OPENRESTY_BUILD_TRARGRT_DIR/openssl
    local pcre=$OPENRESTY_BUILD_TRARGRT_DIR/pcre

    # local START_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));
    # make -j${RESTY_J}
    # local END_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));

    # local START_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));
    # make -j${RESTY_J} install
    # local END_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));

    # echo "ENV PATH=\$PATH:$OPENRESTY_BUILD_TRARGRT_DIR/luajit/bin:$OPENRESTY_BUILD_TRARGRT_DIR/nginx/sbin:$OPENRESTY_BUILD_TRARGRT_DIR/bin"
    # echo "wg action build: build openresty over"

    # local END=$(($(date +%s%N)/1000000));
    # openresty-set-path

    echo "all-time: " $(echo "scale=3; $END - $START" | bc) "ms"
    echo "build-openssl: " $(echo "scale=3; $END_OPENSSL-$START_OPENSSL" | bc) "ms"
    echo "build-pcre: " $(echo "scale=3; $END_PCRE-$START_PCRE" | bc) "ms"
    echo "build-openresty: " $(echo "scale=3; $END_OPENRESTY_BUILD-$START_OPENRESTY_BUILD" | bc) "ms"
    echo "install-openresty: " $(echo "scale=3; $END_OPENRESTY_INSTALL-$START_OPENRESTY_INSTALL" | bc) "ms"

}

function openresty-build {
    local openssl=$1
    local pcre=$2
    local END_OPENRESTY_CONFIGURE=$(($(date +%s%N)/1000000));

    local START_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));
    make -j${RESTY_J}
    local END_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));

    local START_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));
    make -j${RESTY_J} install
    local END_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));
    openresty-set-path
    echo "build-openresty: " $(echo "scale=3; $END_OPENRESTY_BUILD-$START_OPENRESTY_BUILD" | bc) "ms"
    echo "install-openresty: " $(echo "scale=3; $END_OPENRESTY_INSTALL-$START_OPENRESTY_INSTALL" | bc) "ms"
    md5sum `which nginx`
}

function openresty-set-path {
    local OPENRESTY_BUILD_TRARGRT_DIR=${OPENRESTY_BUILD_TRARGRT_DIR:-$1}
    echo "base is " $OPENRESTY_BUILD_TRARGRT_DIR
    if  [[ "$PATH" != "$OPENRESTY_BUILD_TRARGRT_DIR"* ]] ; then
        echo "use nginx in $OPENRESTY_BUILD_TRARGRT_DIR"
        export PATH="$OPENRESTY_BUILD_TRARGRT_DIR/nginx/sbin:$PATH"
    fi
    echo $PATH
    which nginx
	rm ./t/nginx
    ln -s $OPENRESTY_BUILD_TRARGRT_DIR/nginx/sbin/nginx ./t/nginx
}

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
    openresty-set-path   ~/sm/temp/openresty-wg
    prove -I ./vendor/test-nginx/lib -r ./t
}

function openresty-my-test {
    openresty-set-path  ~/sm/temp/openresty-wg
    prove -I ./vendor/test-nginx/lib -r ./t/mine.t
    echo $PWD
    nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf
    openresty-perf-flamegraph

    pkill nginx
}

function openresty-perf-flamegraph {
# prove -I ./vendor/test-nginx/lib -r ./t/mine.t; nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf; . ./actions/openresty.actions.sh; openresty-flamegraph
    sudo  perf record -p "$1" -F 99 -a -g &
    local pid=$!
    local n=10
    echo "perf run in bg $pid wait $n s"
    echo  $PWD
    sleep $n
    sudo kill -INT $pid
    sleep 1
    sudo chmod a+rw ./perf.data
    perf script > perf.bt
    /home/cong/sm/lab/FlameGraph/stackcollapse-perf.pl perf.bt > perf.cbt
    /home/cong/sm/lab/FlameGraph/flamegraph.pl perf.cbt > perf.svg
    firefox ./perf.svg
}

function openresty-profile-bcc-flamegraph {
    local n=10
    echo "will run  bcc profile $pid wait $n s"
    sudo PROBE_LIMIT=100000  ~/sm/lab/bcc/tools/profile.py  --stack-storage-size 204800  -af -p `pgrep nginx` 10 > profile.stacks
    /home/cong/sm/lab/FlameGraph/flamegraph.pl < ./profile.stacks > ./profile.stacks.svg
    firefox ./profile.stacks.svg &
}

function openresty-gdb {
    echo "you must stop bpftrace for the process first"
    local pid=$(ps -aux |grep nginx |grep 'openresty-wg' |awk '{print $2}')
    local gdbinit=$(cat <<EOF
    info functions eyes
EOF
);
    echo "$gdbinit" > ./gdbinit
    sudo ugdb -p $pid -x ./gdbinit
    return 
}

function ngx-on-epoll-process-event {
code=$(cat <<EOF
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
);echo "$code"; sudo  bpftrace -e "$code" 
}


function gdb-steal-nginx-global-variable-address {
    local name=$1
    local gdbinit=$(cat <<EOF
    set confirm off
    p &$name
    quit
EOF
);
    echo "$gdbinit" > ./gdbinit
    sudo gdb -q -p $(pgrep nginx) -x ./gdbinit 2>&1 |grep $name | rg -o '0x.*\s'
}

function ngx-show-global-accept {
    # https://github.com/iovisor/bpftrace/issues/75
    local address=$(gdb-steal-nginx-global-variable-address ngx_stat_accepted0)
    local code=$(cat <<EOF
uretprobe:./t/nginx: ngx_event_accept {\$p=$address;printf(" ngx_event_accept ret %d\n",*\$p);}
EOF
);
    echo $code
    sudo bpftrace -e "$code"
}

# mkdir -p ./t/servroot/logs &&  nginx -c $PWD/t/flame/nginx.lua.conf -p  $PWD/t -e $PWD/t/servroot/logs/error.log

function openresty-build-openssl() ( 

    local source=$OPENRESTY_SOURCE_BASE
    local vendor=$source/vendor
    local openssl_base=$vendor/openssl-1.1.1l
    local j=$RESTY_J
    echo "wg action build: build openssl start"

    cd $openssl_base
    ## patch openssl
    cat  ../openssl-1.1.1f-sess_set_get_cb_yield.patch | patch -p1
    ./config \
    no-threads shared zlib -g \
    enable-ssl3 enable-ssl3-method \
    --prefix=$OPENRESTY_BUILD_TRARGRT_DIR/openssl \
    --libdir=lib \
    -Wl,-rpath,$OPENRESTY_BUILD_TRARGRT_DIR/openssl/lib
    
    make -j$j
    make -j$j install_sw
    echo "wg action build: build openssl over"
 )


function openresty-build-pcre() ( 
    # build pcre
    local pcre=$OPENRESTY_BUILD_TRARGRT_DIR/pcre
    local source=$OPENRESTY_SOURCE_BASE
    local vendor=$source/vendor
    local j=$RESTY_J
    local START_PCRE=$(($(date +%s%N)/1000000));
    cd $vendor/pcre-8.44
    
    echo "wg action build: build pcre start"
    ./configure \
    --prefix=$pcre \
    --disable-cpp \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties
    make -j$j
    make -j$j install
    echo "wg action build: build pcre over"
)

# gen-config
#   - build-luajit
#   - build-lua-module  
#   - build-resty-cli
#   - build-resty-doc
#   - gen-makefile
function openresty-build-resty {
    local START_GEN_CFG=$(date +%s%3N)
    local openssl=${1:=$OPENRESTY_BUILD_TRARGRT_DIR/openssl}
    local pcre=${2:=$OPENRESTY_BUILD_TRARGRT_DIR/pcre}
    local source=$OPENRESTY_SOURCE_BASE
    echo $openssl
    echo $pcre

    local j=$RESTY_J
    cd $source
    echo "wg action build: build openresty start"
    local cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I/pcre/include -I$openssl/openssl/include -DDDEBUG"
    local cc_opt="$cc_opt  -O1 -fno-omit-frame-pointer"
    ./configure -j$j \
    --prefix=$OPENRESTY_BUILD_TRARGRT_DIR \
    --with-pcre \
    --with-cc-opt="$cc_opt" \
    --with-ld-opt="-L $pcre/lib -L $openssl/lib -Wl,-rpath,$pcre/lib:$openssl/lib" \
    --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' \
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --with-poll_module \
    --with-debug
    local END_GEN_CFG=$(date +%s%3N)
    echo "configure-openresty: $(_format_time_diff $START_GEN_CFG $END_GEN_CFG)"
}

function _format_time_diff() {
    local start=$1
    local end=$2
    echo $(echo "scale=3; ($end-$start)/1000" | bc)s
}