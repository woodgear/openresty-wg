#!/bin/bash

RESTY_J=10

function openresty-force-clean {
  git restore -s@ -SW -- ./ && git clean -d -x -f
}

function openresty-clean-build {
  rm -rf Makefile
  rm -rf ./build/*
  rm -rf ./target/*
}

function openresty-sync-submodules {
  git submodule update --recursive --remote
}

function openresty-docker {
  docker build -t openresty-wg:$(date +"%Y-%m-%d-%H-%M-%S") -f ./actions/Dockerfile .
}

# apt-get install zlib1g-dev libpcre3-dev unzip  libssl-dev perl make build-essential curl libxml2-dev libxslt1-dev ca-certificates  gettext-base libgd-dev libgeoip-dev  libncurses5-dev libperl-dev libreadline-dev libxslt1-dev
# apk add git bash build-base coreutils curl gd-dev geoip-dev libxslt-dev linux-headers make perl-dev readline-dev zlib-dev gd geoip libgcc libxslt zlib -y
function openresty-build-dep-arch {
  yay -S bc geoip automake m4
  # make pcre-8.45 happy
  sudo ln -s /usr/bin/aclocal /usr/bin/aclocal-1.16
  sudo ln -s /usr/bin/automake /usr/bin/automake-1.16
}

function openresty-build-in-docker {
  local source=${OPENRESTY_SOURCE_BASE}
  local target=${OPENRESTY_BUILD_TRARGRT_DIR:-$1}
  cd $source
  openresty-full-build
}

function openresty-init-env() (
  export OPENRESTY_SOURCE_BASE=$PWD
  export OPENRESTY_BUILD_TRARGRT_DIR=$OPENRESTY_SOURCE_BASE/target/
)

function openresty-build-waf() (
  cd ./vendor/modsecurity
  ./build.sh
  ./configure
  make
  sudo make install
)

function openresty-full-build() (
  set -e
  #if [ -n "$(git status --porcelain)" ] && [ -z "$IGNORE_DITY_ROOM" ]; then
  #    echo "workdir not clean use '    git restore -s@ -SW  --  ./ && git clean -d -x -f' if you want"
  #    return
  #fi
  openresty-init-env
  local start=$(date +%s%3N)
  local source=${OPENRESTY_SOURCE_BASE}
  local target=${OPENRESTY_BUILD_TRARGRT_DIR}

  if [ -z "$source" ]; then
    echo "OPENRESTY_SOURCE_BASE could not be empty"
    exit 1
  fi

  if [ -z "$target" ]; then
    echo "OPENRESTY_BUILD_TRARGRT_DIR could not be empty"
    exit 1
  fi
  echo $source
  echo $target
  mkdir -p $target
  mkdir -p $source/build

  echo "start build " >$target/build.record
  local openssl=$target/openssl
  local pcre=$target/pcre
  local luajit=$target/luajit
  echo "wg action build: source base is $source target base is $target"
  if [ ! -d "$openssl" ]; then
    openresty-build-openssl
  fi
  if [ ! -d "$pcre" ]; then
    openresty-build-pcre
  fi
  if [ ! -d "$luajit" ]; then
    openresty-build-luajit
  fi

  if [ ! -f Makefile ]; then
    openresty-gen-make $openssl $pcre $luajit
  fi

  openresty-build-lua-and-nginx
  openresty-build-extra-lua
  openresty-relink

  local end=$(date +%s%3N)
  echo "build: all : $(_format_time_diff $start $end)" | tee -a $target/build.record
  keep-gitkeep
  cat $target/build.record
  tree $target
)

function openresty-relink() (
  local target=${OPENRESTY_BUILD_TRARGRT_DIR}
  sudo rm -rf /usr/local/bin/nginx
  sudo ln -s $target/nginx/sbin/nginx /usr/local/bin/nginx
  sudo setcap CAP_NET_BIND_SERVICE=+eip $target/nginx/sbin/nginx
  which nginx
  nginx -V
)

function keep-gitkeep() {
  touch $source/build/.gitkeep
  touch $source/target/.gitkeep
}

function openresty-build-extra-lua() (
  ./actions/alb-nginx-install-deps.sh
)

function openresty-build-openssl() (
  local start=$(date +%s%3N)
  local source=$OPENRESTY_SOURCE_BASE
  local target=${OPENRESTY_BUILD_TRARGRT_DIR}
  local vendor=$source/vendor
  local j=$RESTY_J

  #   RESTY_OPENSSL_VERSION="1.1.1w"
  RESTY_OPENSSL_PATCH_VERSION="1.1.1f"

  echo "wg action build: build openssl start"
  cp -rp $vendor/openssl $source/build/
  cd $source/build/openssl
  ## patch openssl
  cat $vendor/openssl-$RESTY_OPENSSL_PATCH_VERSION-sess_set_get_cb_yield.patch | patch -p1
  ./config \
    no-threads shared zlib -g \
    enable-ssl3 enable-ssl3-method \
    --prefix=$OPENRESTY_BUILD_TRARGRT_DIR/openssl \
    --libdir=lib \
    -Wl,-rpath,$OPENRESTY_BUILD_TRARGRT_DIR/openssl/lib

  make -j$j
  make -j$j install_sw
  local end=$(date +%s%3N)
  tree $OPENRESTY_BUILD_TRARGRT_DIR/openssl
  echo "build: openssl : $(_format_time_diff $start $end)" | tee -a $target/build.record
)

function openresty-build-pcre() (
  # build pcre
  local start=$(date +%s%3N)
  local pcre_target=$OPENRESTY_BUILD_TRARGRT_DIR/pcre
  local source=$OPENRESTY_SOURCE_BASE
  local target=${OPENRESTY_BUILD_TRARGRT_DIR}
  local vendor=$source/vendor
  local j=$RESTY_J

  RESTY_PCRE_VERSION="8.45"
  local pcre_ver="pcre-$RESTY_PCRE_VERSION"
  cp -rp $vendor/$pcre_ver $source/build/
  cd $source/build/$pcre_ver

  echo "wg action build: build pcre start"
  ./configure \
    --prefix=$pcre_target \
    --disable-cpp \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties
  make -j$j
  make -j$j install
  echo "wg action build: build pcre over"
  local end=$(date +%s%3N)
  tree $pcre_target
  echo "build: pcre : $(_format_time_diff $start $end)" | tee -a $target/build.record
)

function openresty-build-luajit() (
  local start=$(date +%s%3N)
  local source=$OPENRESTY_SOURCE_BASE
  local target=$OPENRESTY_BUILD_TRARGRT_DIR
  local luajit=$OPENRESTY_BUILD_TRARGRT_DIR/luajit

  cp -rp $source/vendor/luajit2 $source/build/
  cd $source/build/luajit2
  local xcflags_enable_with_debug="-DLUA_USE_APICHECK -DLUA_USE_ASSERT"
  local xcflags_custom="-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT"
  make -j10 TARGET_STRIP=@: CCDEBUG=-g Q= XCFLAGS="$xcflags_enable_with_debug $xcflags_custom" CC=cc PREFIX=$luajit
  make install TARGET_STRIP=@: CCDEBUG=-g Q= XCFLAGS="$xcflags_enable_with_debug $xcflags_custom" CC=cc PREFIX=$luajit
  local end=$(date +%s%3N)
  tree $luajit
  echo "build: luiajit: $(_format_time_diff $start $end)" | tee -a $target/build.record
)

# gen-config
#   - build-luajit
#   - build-lua-module
#   - build-resty-cli
#   - build-resty-doc
#   - gen-makefile
function openresty-gen-make {
  local START_GEN_CFG=$(date +%s%3N)
  local openssl=${1:=$OPENRESTY_BUILD_TRARGRT_DIR/openssl}
  local pcre=${2:=$OPENRESTY_BUILD_TRARGRT_DIR/pcre}
  local luajit=${3:=$OPENRESTY_BUILD_TRARGRT_DIR/luajit}
  local source=$OPENRESTY_SOURCE_BASE
  local target=$OPENRESTY_BUILD_TRARGRT_DIR
  echo $openssl
  echo $pcre
  echo $luajit

  local j=$RESTY_J
  cd $source
  echo "wg action build: build openresty start"
  # ignore those dd(xx) log
  # local cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I$pcre/include -I$openssl/include -DDDEBUG"
  local cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I$pcre/include -I$openssl/include"
  local cc_opt="$cc_opt  -O1 -fno-omit-frame-pointer"

  # make it does not build luajit  again
  rm -rf ./bundle/LuaJIT-2.1-20231117
  # make sure use our nginx. in fact it will copy to build
  rm -rf $source/bundle/nginx-1.25.3
  cp -rp $source/vendor/nginx $source/bundle/nginx-1.25.3
  echo "do configure"
  # make -j10 TARGET_STRIP=@: CCDEBUG=-g Q= XCFLAGS='-DLUA_USE_APICHECK -DLUA_USE_ASSERT -DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' CC=cc PREFIX=/home/cong/sm/temp/openresty-wg/luajit
  ./configure -j$j \
    --prefix=$OPENRESTY_BUILD_TRARGRT_DIR \
    --with-pcre \
    --with-cc-opt="$cc_opt" \
    --with-ld-opt="-L $pcre/lib -L $openssl/lib -Wl,-rpath,$pcre/lib:$openssl/lib" \
    --with-luajit="$luajit" \
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
    --with-http_v3_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --with-debug \
    --without-http_redis_module \
    --add-module=$PWD/vendor/ModSecurity-nginx \
    --build=ALB

  local END_GEN_CFG=$(date +%s%3N)
  echo "configure-openresty: $(_format_time_diff $START_GEN_CFG $END_GEN_CFG)" | tee -a $target/build.record
}

function openresty-build-lua-and-nginx {

  local target=$OPENRESTY_BUILD_TRARGRT_DIR
  local start=$(date +%s%3N)
  make -j${RESTY_J}
  local end=$(date +%s%3N)
  make -j${RESTY_J} install
  local end1=$(date +%s%3N)
  echo "build: make : $(_format_time_diff $start $end)" | tee -a $target/build.record
  echo "build: make-install : $(_format_time_diff $end $end1)" | tee -a $target/build.record
}

function openresty-set-path {
  sudo ln -s $OPENRESTY_BUILD_TRARGRT_DIR/nginx/sbin/nginx /usr/bin/wg-nginx
}

# mkdir -p ./t/servroot/logs &&  nginx -c $PWD/t/flame/nginx.lua.conf -p  $PWD/t -e $PWD/t/servroot/logs/error.log

function _format_time_diff() {
  local start=$1
  local end=$2
  echo $(echo "scale=3; ($end-$start)/1000" | bc)s
}
