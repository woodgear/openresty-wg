function openresty_build() {
    # export OPENRESTY_SOURCE_BASE=/home/cong/sm/lab/openresty-1.19.3.2 first
    SOURCE_BASE=$OPENRESTY_SOURCE_BASE
    OPENRESTY_BASE=$1
    echo "wg action build: source base is $SOURCE_BASE target base is $OPENRESTY_BASE"
    VENDOR=$SOURCE_BASE/vendor
    OPENSSL_BASE=$VENDOR/openssl-1.1.1l
    OPENRESTY_SOURCE=$SOURCE_BASE/vendor
    # add build dependency
    # apk add --no-cache --virtual .build-deps \
    #         build-base \
    #         coreutils \
    #         curl \
    #         gd-dev \
    #         geoip-dev \
    #         libxslt-dev \
    #         linux-headers \
    #         make \
    #         perl-dev \
    #         readline-dev \
    #         zlib-dev
    # # add run dependency
    #     && apk add --no-cache 
    #         gd \ ## 动态创建图片
    #         geoip \
    #         libgcc \
    #         libxslt \
    #         zlib


    # build openssl
    RESTY_J=10
    cd $OPENSSL_BASE

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
    echo "wg action build: build openssl over"

    # build pcre
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
    echo "wg action build: build pcre over"

    cd $SOURCE_BASE
    echo "wg action build: build openresty start"
    ./configure -j${RESTY_J} \
    	--prefix=$OPENRESTY_BASE \
    	--with-pcre \
        --with-cc-opt="-DNGX_LUA_ABORT_AT_PANIC -I/pcre/include -I$OPENRESTY_BASE/openssl/include" \
        --with-ld-opt="-L$OPENRESTY_BASE/pcre/lib -L$OPENRESTY_BASE/openssl/lib -Wl,-rpath,$OPENRESTY_BASE/pcre/lib:$OPENRESTY_BASE/openssl/lib" \
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
        --with-threads

    make -j${RESTY_J} 
    make -j${RESTY_J} install

    echo "wg action build: build openresty over"
}