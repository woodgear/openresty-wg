#!/bin/bash


function openresty-force-clean() {
    git restore -s@ -SW  --  ./ && git clean -d -x -f
}

function openresty-full-build() {
    # export OPENRESTY_SOURCE_BASE=/home/cong/sm/lab/openresty-1.19.3.2 first
    if [ -n "$(git status --porcelain)" ] && [ -z "$IGNORE_DITY_ROOM" ]; then 
        echo "workdir not clean use '    git restore -s@ -SW  --  ./ && git clean -d -x -f' if you want"
    fi


    local START=$(($(date +%s%N)/1000000));
    SOURCE_BASE=$OPENRESTY_SOURCE_BASE
    OPENRESTY_BASE=${OPENRESTY_BASE:-$1}

    if [ -z "$OPENRESTY_SOURCE_BASE" ] ; then
        echo "OPENRESTY_SOURCE_BASE could not be empty"
        return 1
    fi

    if [ -z "$OPENRESTY_BASE" ] ; then
        echo "OPENRESTY_BASE could not be empty"
        return 1
    fi
    echo "wg action build: source base is $SOURCE_BASE target base is $OPENRESTY_BASE"
    return 
    VENDOR=$SOURCE_BASE/vendor
    OPENSSL_BASE=$VENDOR/openssl-1.1.1l
    OPENRESTY_SOURCE=$SOURCE_BASE/vendor

    # build openssl
    RESTY_J=10


    cd $OPENSSL_BASE
    local START_OPENSSL=$(($(date +%s%N)/1000000));
    echo "wg action build: build openssl start"
    # https://stackoverflow.com/a/15404733
    git restore -s@ -SW  --  ./
    ## patch openssl
    cat  ../openssl-1.1.1f-sess_set_get_cb_yield.patch | patch -p1
    ./config \
    no-threads shared zlib -g \
    enable-ssl3 enable-ssl3-method \
    --prefix=$OPENRESTY_BASE/openssl \
    --libdir=lib \
    -Wl,-rpath,$OPENRESTY_BASE/openssl/lib
    
    make -j${RESTY_J}
    make -j${RESTY_J} install_sw
    local END_OPENSSL=$(($(date +%s%N)/1000000));
    echo "wg action build: build openssl over"
    
    # build pcre
    local START_PCRE=$(($(date +%s%N)/1000000));
    cd $VENDOR/pcre-8.44
    
    echo "wg action build: build pcre start"
    ./configure \
    --prefix=$OPENRESTY_BASE/pcre \
    --disable-cpp \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties
    make -j${RESTY_J}
    make -j${RESTY_J} install
    local END_PCRE=$(($(date +%s%N)/1000000));
    echo "wg action build: build pcre over"
    
    cd $SOURCE_BASE
    local START_OPENRESTY=$(($(date +%s%N)/1000000));
    echo "wg action build: build openresty start"
    local cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I/pcre/include -I$OPENRESTY_BASE/openssl/include"
    local cc_opt="$cc_opt  -O1 -fno-omit-frame-pointer"
    ./configure -j${RESTY_J} \
    --prefix=$OPENRESTY_BASE \
    --with-pcre \
    --with-cc-opt="$cc_opt" \
    --with-ld-opt="-L$OPENRESTY_BASE/pcre/lib -L$OPENRESTY_BASE/openssl/lib -Wl,-rpath,$OPENRESTY_BASE/pcre/lib:$OPENRESTY_BASE/openssl/lib" \
    --without-luajit-gc64 \
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
    
    local END_OPENRESTY_CONFIGURE=$(($(date +%s%N)/1000000));

    local START_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));
    make -j${RESTY_J}
    local END_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));

    local START_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));
    make -j${RESTY_J} install
    local END_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));

    echo "ENV PATH=\$PATH:$OPENRESTY_BASE/luajit/bin:$OPENRESTY_BASE/nginx/sbin:$OPENRESTY_BASE/bin"
    echo "wg action build: build openresty over"

    local END=$(($(date +%s%N)/1000000));

    echo "all-time: " $(echo "scale=3; $END - $START" | bc) "ms"
    echo "build-openssl: " $(echo "scale=3; $END_OPENSSL-$START_OPENSSL" | bc) "ms"
    echo "build-pcre: " $(echo "scale=3; $END_PCRE-$START_PCRE" | bc) "ms"
    echo "configure-openresty: " $(echo "scale=3; $END_OPENRESTY_CONFIGURE-$START_OPENRESTY" | bc) "ms"
    echo "build-openresty: " $(echo "scale=3; $END_OPENRESTY_BUILD-$START_OPENRESTY_BUILD" | bc) "ms"
    echo "install-openresty: " $(echo "scale=3; $END_OPENRESTY_INSTALL-$START_OPENRESTY_INSTALL" | bc) "ms"

}

function openresty-build() {
    # you need full-build first
    local END_OPENRESTY_CONFIGURE=$(($(date +%s%N)/1000000));

    local START_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));
    make -j${RESTY_J}
    local END_OPENRESTY_BUILD=$(($(date +%s%N)/1000000));

    local START_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));
    make -j${RESTY_J} install
    local END_OPENRESTY_INSTALL=$(($(date +%s%N)/1000000));
    echo "build-openresty: " $(echo "scale=3; $END_OPENRESTY_BUILD-$START_OPENRESTY_BUILD" | bc) "ms"
    echo "install-openresty: " $(echo "scale=3; $END_OPENRESTY_INSTALL-$START_OPENRESTY_INSTALL" | bc) "ms"
    md5sum `which nginx`
}

function _set_path() {
    local OPENRESTY_BASE=$1
    echo "base is " $OPENRESTY_BASE
    if  [[ "$PATH" != "$OPENRESTY_BASE"* ]] ; then
        echo "use nginx in $OPENRESTY_BASE"
        export PATH="$OPENRESTY_BASE/nginx/sbin:$PATH"
    fi
    echo $PATH
    which nginx
}

function openresty-my-test-all() {
    _set_path   ~/sm/temp/openresty-wg
    prove -I ./vendor/test-nginx/lib -r ./t
}

function openresty-my-test() {
    _set_path  ~/sm/temp/openresty-wg
    prove -I ./vendor/test-nginx/lib -r ./t/mine.t
    echo $PWD
    nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf
    openresty-perf-flamegraph

    pkill nginx
}

function openresty-perf-flamegraph() {
# prove -I ./vendor/test-nginx/lib -r ./t/mine.t; nginx -p $PWD/t/servroot -c $PWD/t/servroot/conf/nginx.conf; . ./actions/openresty.actions.sh; openresty-flamegraph
    sudo  perf record -p `pgrep nginx` -F 99 -a -g &
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

function openresty-profile-bcc-flamegraph() {
    local n=10
    echo "will run  bcc profile $pid wait $n s"
    sudo PROBE_LIMIT=100000  ~/sm/lab/bcc/tools/profile.py  --stack-storage-size 204800  -af -p `pgrep nginx` 10 > profile.stacks
    /home/cong/sm/lab/FlameGraph/flamegraph.pl < ./profile.stacks > ./profile.stacks.svg
    firefox ./profile.stacks.svg &
}

function openresty-run-lua-restry-core-test() {

}